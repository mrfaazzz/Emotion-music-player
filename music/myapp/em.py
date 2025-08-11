# import keras
# import cv2
# from keras.models import model_from_json
# from keras.preprocessing import image
# from keras.preprocessing.image import ImageDataGenerator
#
# import numpy as np
#
# model = model_from_json(open(r"C:\Users\mrfaa\PycharmProjects\music\myapp\facial_expression_model_structure.json", "r").read())
# model.load_weights(r'C:\Users\mrfaa\PycharmProjects\music\myapp\facial_expression_model_weights.h5')  # load weights
#
#
#
# face_cascade = cv2.CascadeClassifier(r'C:\Users\mrfaa\PycharmProjects\music\myapp\haarcascade_frontalface_default.xml')
#
# cap = cv2.VideoCapture(0)
#
#
# emotions = ('angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral')
#
# def camclick(img):
#     i=0
#     while(True):
#         # ret, img = cap.read()
#
#         # img = cv2.imread('../11.jpg')
#         # cv2.imwrite(str(i)+".jpg",img)
#         i=i+1
#
#         gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#
#         faces = face_cascade.detectMultiScale(gray, 1.3, 5)
#
#         #print(faces) #locations of detected faces
#         emotion=None
#
#         for (x,y,w,h) in faces:
#             cv2.rectangle(img,(x,y),(x+w,y+h),(255,0,0),2) #draw rectangle to main image
#
#             detected_face = img[int(y):int(y+h), int(x):int(x+w)] #crop detected face
#             detected_face = cv2.cvtColor(detected_face, cv2.COLOR_BGR2GRAY) #transform to gray scale
#             detected_face = cv2.resize(detected_face, (48, 48)) #resize to 48x48
#
#             img_pixels = image.img_to_array(detected_face)
#             img_pixels = np.expand_dims(img_pixels, axis = 0)
#
#             img_pixels /= 255 #pixels are in scale of [0, 255]. normalize all pixels in scale of [0, 1]
#
#             predictions = model.predict(img_pixels) #store probabilities of 7 expressions
#
#             #find max indexed array 0: angry, 1:disgust, 2:fear, 3:happy, 4:sad, 5:surprise, 6:neutral
#             max_index = np.argmax(predictions[0])
#
#             emotion = emotions[max_index]
#             cv2.putText(img,emotion,(x,y-5),cv2.FONT_HERSHEY_SIMPLEX,0.5,(255,0,0),2)
#             print (emotion)
#
#             # if cv2.waitKey(1):
#         cv2.imshow('img', img)
#
#         if cv2.waitKey(1) & 0xFF == ord('q'):  # press q to quit
#             break
#
#         # kill open cv things
#     cap.release()
#     cv2.destroyAllWindows()
#             # 	pass
#         # return emotion
#             #write emotion text above rectangle
#
# # camclick()



import os
import json
import cv2
import numpy as np
import tensorflow as tf
from django.http import HttpResponse
from django.core.files.storage import FileSystemStorage
from keras.models import model_from_json
from keras.preprocessing import image

# Load TensorFlow Graph & Session
graph = tf.compat.v1.get_default_graph()
session = tf.compat.v1.Session()

# Load Model inside Graph Context
with session.as_default():
    with graph.as_default():
        model = model_from_json(open(r"C:\Users\mrfaa\PycharmProjects\123\music\myapp\facial_expression_model_structure.json", "r").read())
        model.load_weights(r'C:\Users\mrfaa\PycharmProjects\123\music\myapp\facial_expression_model_weights.h5')

# Load Haar Cascade for Face Detection
face_cascade = cv2.CascadeClassifier(r'C:\Users\mrfaa\PycharmProjects\123\music\myapp\haarcascade_frontalface_default.xml')

# Emotion Labels
emotions = ('angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral')

def camclick(img_path):
    global graph, session  # Use global session

    img = cv2.imread(img_path)
    if img is None:
        print("Error: Unable to read the image file.")
        return None

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.3, 5)
    emotion = None

    for (x, y, w, h) in faces:
        detected_face = gray[y:y + h, x:x + w]
        detected_face = cv2.resize(detected_face, (48, 48))

        img_pixels = image.img_to_array(detected_face)
        img_pixels = np.expand_dims(img_pixels, axis=0)
        img_pixels /= 255  # Normalize pixel values

        with session.as_default():
            with graph.as_default():
                predictions = model.predict(img_pixels)
                max_index = np.argmax(predictions[0])
                emotion = emotions[max_index]

    return emotion

