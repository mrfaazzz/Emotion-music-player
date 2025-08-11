


def image_capture(queue):
    vidFile = cv2.VideoCapture(0)
    while True:
        flag, frame=vidFile.read()
        frame = cv2.cvtColor(frame,cv2.cv.CV_BGR2RGB)
        queue.put(frame)
        cv2.waitKey(10)


