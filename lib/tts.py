import pyttsx3

global engine
engine = pyttsx3.init()


def initEngine() -> str:
    voices = engine.getProperty('voices')
    engine.setProperty('voice', voices[1].id)
    engine.setProperty('rate', 240)
    f = open("./.temp/comments.txt", 'r', encoding="utf8")
    return f.read()

def generateTTS(comments:str):
    engine.save_to_file(f'<pitch absmiddle="7">{comments}</pitch>', './test2.wav')
    engine.runAndWait()

generateTTS(initEngine())