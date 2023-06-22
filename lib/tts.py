import pyttsx3

engine = pyttsx3.init()
voices = engine.getProperty('voices')
engine.setProperty('voice', voices[1].id)
engine.setProperty('rate', 130)
engine.save_to_file('<pitch absmiddle="7">Hello this is a test lol xD</pitch>', './test2.wav')
engine.runAndWait()
