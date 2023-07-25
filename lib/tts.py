from transformers import SpeechT5Processor, SpeechT5ForTextToSpeech, SpeechT5HifiGan
from datasets import load_dataset
import torch
import soundfile as sf
import sys
from gtts import gTTS

# select cuda if available as it can lead to quicker output times
device = "cuda" if torch.cuda.is_available() else "cpu"

# load all of the models and data necessary (Speecht5)
processor = SpeechT5Processor.from_pretrained("microsoft/speecht5_tts")
model = SpeechT5ForTextToSpeech.from_pretrained("microsoft/speecht5_tts").to(device)
vocoder = SpeechT5HifiGan.from_pretrained("microsoft/speecht5_hifigan").to(device)
embeddings_dataset = load_dataset("Matthijs/cmu-arctic-xvectors", split="validation")

# create a dictionary for each possible speaker (hard to remember otherwise)
speakers = {
    "awb": 0,  # Scottish male
    "bdl": 1138,  # US male
    "clb": 2271,  # US female
    "jmk": 3403,  # Canadian male
    "ksp": 4535,  # Indian male
    "rms": 5667,  # US male
    "slt": 6799,  # US female
}


def generateNTTS(text, count, speaker=6799):
    """
    Generate .wav tts files using neural tts models (speecht5)
    """
    # text -> tts
    inputs = processor(text=text, return_tensors="pt").to(device)
    xvector = (
        torch.tensor(embeddings_dataset[speaker]["xvector"]).unsqueeze(0).to(device)
    )
    speech = model.generate_speech(inputs["input_ids"], xvector, vocoder=vocoder)
    output_filename = f"tts-{count}.wav"
    # write to file with sr 16k otherwise it can cause issues
    sf.write(f"./.temp/tts/{output_filename}", speech.numpy(), samplerate=16000)


def generateGTTS(text, count):
    """
    Generate .wav tts files using the GTTS python module which leverages Google Translate's tts API

    ∴ requires internet in order to work
    """
    # send a request with the specified text and the accent which is the 4th argument sent
    speech = gTTS(text=text, lang="en", slow=False, tld=sys.argv[4])
    # write to file
    output_filename = f"tts-{count}.wav"
    speech.save(f"./.temp/tts/{output_filename}")


# only runs the code when the program is run directly (not as a lib)
if __name__ == "__main__":
    # select data from the cli
    text = sys.argv[1]
    count = sys.argv[2]
    # if the user has ntts arg set to true
    if sys.argv[3] == "1":
        generateNTTS(text, count)
    else:
        generateGTTS(text, count)
