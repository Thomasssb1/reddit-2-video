from transformers import SpeechT5Processor, SpeechT5ForTextToSpeech, SpeechT5HifiGan
from datasets import load_dataset
import torch
import random
import string
import soundfile as sf
import json
import sys
from gtts import gTTS

device = "cuda" if torch.cuda.is_available() else "cpu"

processor = SpeechT5Processor.from_pretrained("microsoft/speecht5_tts")
model = SpeechT5ForTextToSpeech.from_pretrained("microsoft/speecht5_tts").to(device)
vocoder = SpeechT5HifiGan.from_pretrained("microsoft/speecht5_hifigan").to(device)
embeddings_dataset = load_dataset("Matthijs/cmu-arctic-xvectors", split="validation")

speakers = {
    "awb": 0,  # Scottish male
    "bdl": 1138,  # US male
    "clb": 2271,  # US female
    "jmk": 3403,  # Canadian male
    "ksp": 4535,  # Indian male
    "rms": 5667,  # US male
    "slt": 6799,  # US female
}

f = open("./.temp/comments.json", "r", encoding="utf8")
data = json.load(f)


def generateNTTS(text, count, speaker=6799):
    inputs = processor(text=text, return_tensors="pt").to(device)
    xvector = (
        torch.tensor(embeddings_dataset[speaker]["xvector"]).unsqueeze(0).to(device)
    )
    speech = model.generate_speech(inputs["input_ids"], xvector, vocoder=vocoder)
    output_filename = f"tts-{count}.wav"
    sf.write(f"./.temp/tts/{output_filename}", speech.numpy(), samplerate=16000)


def generateGTTS(text, count):
    speech = gTTS(text=text, lang="en", slow=False, tld=data["settings"]["accent"])
    output_filename = f"tts-{count}.wav"
    speech.save(f"./.temp/tts/{output_filename}")


for count, comment in enumerate(data["text"]):
    if data["settings"]["ntts"]:
        generateNTTS(comment, count)
    else:
        generateGTTS(comment, count)
