# Bundled fonts

All fonts are licensed under the SIL Open Font License 1.1 (see the `*-OFL.txt` files).

| File | Source | Notes |
| --- | --- | --- |
| `Inter-Variable.ttf` | google/fonts `ofl/inter/Inter[opsz,wght].ttf` | Optical size pinned to 14 and subset to Latin + punctuation (876 KB → 269 KB) for faster web loads. The weight axis is kept. Arabic script uses Vazirmatn. |
| `Vazirmatn-Variable.ttf` | google/fonts `ofl/vazirmatn/Vazirmatn[wght].ttf` | Unmodified. Persian/Arabic script and its own Latin. |
| `Cinzel-Variable.ttf` | google/fonts `ofl/cinzel/Cinzel[wght].ttf` | Unmodified. Short Latin display text only. |

Regenerate Inter (requires `fonttools`):

```bash
python3 -m fontTools.varLib.instancer "Inter[opsz,wght].ttf" opsz=14 -o inter-opsz.ttf
python3 -m fontTools.subset inter-opsz.ttf \
  --unicodes="U+0000-024F,U+0259,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0300-0301,U+2000-206F,U+20AC,U+2122,U+2190-2199,U+2212,U+2215,U+2713,U+FEFF,U+FFFD" \
  --layout-features='*' --output-file=Inter-Variable.ttf
```
