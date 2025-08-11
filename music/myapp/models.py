from django.db import models

# Create your models here.
class login_table(models.Model):
    username=models.CharField(max_length=30)
    password=models.CharField(max_length=30)
    type=models.CharField(max_length=30)


class user_table(models.Model):
    LOGIN=models.ForeignKey(login_table,on_delete=models.CASCADE)
    name=models.CharField(max_length=30)
    email=models.CharField(max_length=30)
    phone=models.BigIntegerField()
    image = models.FileField()
    place=models.CharField(max_length=50)
    pin=models.BigIntegerField()
    post=models.CharField(max_length=30)


class song_table(models.Model):
    sname = models.CharField(max_length=255)
    duration=models.CharField(max_length=50)
    emotion=models.CharField(max_length=100)
    song=models.FileField()
    simage = models.ImageField(upload_to='simage/', null=True, blank=True)

class playlist_table(models.Model):
    pname=models.CharField(max_length=20)
    song=models.ForeignKey(song_table,on_delete=models.CASCADE)
    emotion=models.CharField(max_length=100)


class playlist_details_table(models.Model):
    pname=models.ForeignKey(playlist_table,on_delete=models.CASCADE)
    sname=models.ForeignKey(song_table,on_delete=models.CASCADE)

class liked_playlist(models.Model):
    song=models.ForeignKey(song_table,on_delete=models.CASCADE)
    USER=models.ForeignKey(user_table,on_delete=models.CASCADE)

class complaint_table(models.Model):
    reply=models.CharField(max_length=200)
    content=models.CharField(max_length=500)
    date=models.DateField()
    USER=models.ForeignKey(user_table,on_delete=models.CASCADE)


class feedback_table(models.Model):
    content=models.CharField(max_length=500)
    rating=models.FloatField()
    date=models.DateField()
    USER=models.ForeignKey(user_table,on_delete=models.CASCADE)



class Chat(models.Model):
    FROMID= models.ForeignKey(login_table,on_delete=models.CASCADE,related_name="Fromid")
    TOID= models.ForeignKey(login_table,on_delete=models.CASCADE,related_name="Toid")
    message=models.CharField(max_length=100)
    date=models.DateField()


