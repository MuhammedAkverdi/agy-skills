#!/usr/bin/env python3
"""
Local Face Identity QA gate for Sisli Patika v2.
Supports InsightFace (ArcFace) if installed, or Facenet-PyTorch (InceptionResnetV1 vggface2).
"""
import argparse
import json
import sys
import numpy as np
import cv2
from PIL import Image


class FaceEmbedder:
    def __init__(self):
        self.backend = None
        try:
            from insightface.app import FaceAnalysis
            app = FaceAnalysis(name="buffalo_l", providers=["CPUExecutionProvider"])
            app.prepare(ctx_id=-1, det_size=(640, 640))
            self.app = app
            self.backend = "insightface"
        except Exception:
            import torch
            from facenet_pytorch import MTCNN, InceptionResnetV1
            self.device = torch.device("cpu")
            self.mtcnn = MTCNN(image_size=160, margin=20, min_face_size=40, keep_all=True, device=self.device)
            self.resnet = InceptionResnetV1(pretrained="vggface2").eval().to(self.device)
            self.torch = torch
            self.backend = "facenet-pytorch"

    def get_embeddings(self, bgr_img):
        """Return list of (area, score, l2_embedding) sorted largest face first."""
        if bgr_img is None or bgr_img.size == 0:
            return []
        if self.backend == "insightface":
            faces = self.app.get(bgr_img)
            out = []
            for f in faces:
                x1, y1, x2, y2 = f.bbox
                area = max(0.0, float((x2 - x1) * (y2 - y1)))
                emb = f.normed_embedding.astype(np.float32)
                out.append((area, float(f.det_score), emb))
            out.sort(key=lambda t: t[0], reverse=True)
            return out
        else:
            rgb = cv2.cvtColor(bgr_img, cv2.COLOR_BGR2RGB)
            pil = Image.fromarray(rgb)
            boxes, probs = self.mtcnn.detect(pil)
            if boxes is None or len(boxes) == 0:
                return []
            crops = self.mtcnn(pil)
            if crops is None:
                return []
            if crops.ndim == 3:
                crops = crops.unsqueeze(0)
            with self.torch.no_grad():
                embs = self.resnet(crops.to(self.device)).cpu().numpy()
            out = []
            for idx, (box, prob) in enumerate(zip(boxes, probs)):
                if prob is None or prob < 0.85 or idx >= len(embs):
                    continue
                x1, y1, x2, y2 = box
                area = max(0.0, float((x2 - x1) * (y2 - y1)))
                emb = embs[idx].astype(np.float32)
                norm = np.linalg.norm(emb)
                if norm > 0:
                    emb = emb / norm
                out.append((area, float(prob), emb))
            out.sort(key=lambda t: t[0], reverse=True)
            return out


def cosine_sim(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-8))


def read_bgr_unicode(path: str):
    """Read image supporting Unicode Windows paths (e.g. Turkish İ/ü/ö)."""
    data = np.fromfile(path, dtype=np.uint8)
    if data.size == 0:
        return None
    return cv2.imdecode(data, cv2.IMREAD_COLOR)


def load_ref_embedding(embedder: FaceEmbedder, ref_path: str) -> np.ndarray:
    img = read_bgr_unicode(ref_path)
    if img is None:
        raise FileNotFoundError(f"Could not read reference image: {ref_path}")
    faces = embedder.get_embeddings(img)
    if not faces:
        # Retry with center-top crop in case of full-body sheet
        h, w = img.shape[:2]
        crop = img[0:int(h * 0.65), 0:w]
        faces = embedder.get_embeddings(crop)
    if not faces:
        raise RuntimeError(f"No face detected in reference image: {ref_path}")
    return faces[0][2]


def check_image(embedder: FaceEmbedder, ref_emb: np.ndarray, target_path: str):
    img = read_bgr_unicode(target_path)
    if img is None:
        raise FileNotFoundError(f"Could not read target image: {target_path}")
    faces = embedder.get_embeddings(img)
    if not faces:
        return [], 0
    sims = [cosine_sim(ref_emb, f[2]) for f in faces]
    # Take best match among detected faces (in case two people appear)
    return [max(sims)], len(faces)


def check_video(embedder: FaceEmbedder, ref_emb: np.ndarray, video_path: str, samples: int):
    import os
    import shutil
    import tempfile
    tmp_path = None
    open_path = video_path
    cap = cv2.VideoCapture(open_path)
    if not cap.isOpened():
        cap.release()
        fd, tmp_path = tempfile.mkstemp(suffix=".mp4")
        os.close(fd)
        shutil.copy2(video_path, tmp_path)
        open_path = tmp_path
        cap = cv2.VideoCapture(open_path)
    if not cap.isOpened():
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)
        raise FileNotFoundError(f"Could not open video: {video_path}")
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) or 1
    indices = np.linspace(0, max(0, total_frames - 1), num=samples, dtype=int)
    scores = []
    faces_total = 0
    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, int(idx))
        ok, frame = cap.read()
        if not ok or frame is None:
            continue
        faces = embedder.get_embeddings(frame)
        if faces:
            faces_total += len(faces)
            sims = [cosine_sim(ref_emb, f[2]) for f in faces]
            scores.append(max(sims))
    cap.release()
    if tmp_path and os.path.exists(tmp_path):
        os.remove(tmp_path)
    return scores, faces_total


def main():
    parser = argparse.ArgumentParser(description="Automated local face identity QA gate")
    parser.add_argument("--ref", required=True, help="Path to reference face/sheet image")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--target", help="Path to target scene image")
    group.add_argument("--video", help="Path to target video clip")
    parser.add_argument("--samples", type=int, default=4, help="Number of sampled frames for --video")
    parser.add_argument("--threshold", type=float, default=0.50, help="Cosine similarity threshold")
    args = parser.parse_args()

    embedder = FaceEmbedder()
    ref_emb = load_ref_embedding(embedder, args.ref)

    if args.target:
        scores, faces_found = check_image(embedder, ref_emb, args.target)
    else:
        scores, faces_found = check_video(embedder, ref_emb, args.video, args.samples)

    if not scores:
        res = {
            "pass": False,
            "backend": embedder.backend,
            "score": 0.0,
            "min_score": 0.0,
            "faces_found": 0,
            "threshold": args.threshold,
            "error": "no_face_detected_in_target",
        }
        print(json.dumps(res, ensure_ascii=False))
        sys.exit(1)

    mean_score = float(np.mean(scores))
    min_score = float(np.min(scores))
    passed = min_score >= args.threshold
    res = {
        "pass": bool(passed),
        "backend": embedder.backend,
        "score": round(mean_score, 4),
        "min_score": round(min_score, 4),
        "frame_scores": [round(float(s), 4) for s in scores],
        "faces_found": int(faces_found),
        "threshold": args.threshold,
    }
    print(json.dumps(res, ensure_ascii=False))
    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
