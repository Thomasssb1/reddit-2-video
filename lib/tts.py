import json
import pyttsx3
from gtts import gTTS

global engine
engine = pyttsx3.init()


def initEngine():
    voices = engine.getProperty('voices')
    engine.setProperty('voice', voices[0].id)
    engine.setProperty('rate', 240)
    f = open("./.temp/comments.json", 'r', encoding="utf8")
    data = json.load(f)
    return data

def generateTTS(comments:str, offline:bool, accent:str):
    if offline:
        print("Using ttsx3, generating local TTS (male)")
        engine.save_to_file(f'<pitch absmiddle="7">{comments}</pitch>', './.temp/tts.wav')
        engine.runAndWait()
    else:
        print("Using google TTS (female)")
        text = gTTS(text=comments, lang='en', slow=False, tld=accent)
        text.save('./.temp/tts.wav')

data = initEngine()
generateTTS(data['body'], data['settings']['offline'], data['settings']['accent'])