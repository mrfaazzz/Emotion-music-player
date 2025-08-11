import json
from datetime import datetime

import cv2
from django.core.files.storage import FileSystemStorage
from django.db.models import Q
from django.shortcuts import render, redirect
from django.http import JsonResponse
from django.http import HttpResponse

from myapp.em import camclick
from myapp.models import *
from django.contrib import auth


# Create your views here.
def login(request):
    return render(request, 'ADMIN/login.html')

def login_post(request):
    username=request.POST['kkk']
    password=request.POST['mmm']
    print(request.POST)
    print(username, password)
    a = login_table.objects.filter(username=username, password=password)
    print(a)
    if a.exists():
        b = login_table.objects.get(username=username,password=password)
        print(b)
        if b.type == 'admin':

            ob1=auth.authenticate(username='admin',password='admin')
            if ob1 is not None:
                auth.login(request,ob1)
                request.session['1id']=b.id
            return HttpResponse('''<script>alert('admin logined.');window.location='/admin_view'</script>''')
        else:
            return HttpResponse('''<script>alert('invalid.');window.location='/'</script>''')
    else:
        return HttpResponse('''<script>alert('username,password invalid..');window.location='/'</script>''')

# def admin_view(request):
#     return render(request, 'ADMIN/index.html')
def admin_view(request):
    a = feedback_table.objects.select_related('USER').order_by('-rating')[:5]  # Fetch top 5 entries by rating
    return render(request, 'ADMIN/indexadmin.html',{'data':a})
def view_user(request):
    ob=user_table.objects.all()
    return render(request, 'ADMIN/view user.html',{'data':ob})


# def playlist(request):
#     ob=playlist_table.objects.all()
#     return render(request, 'ADMIN/playlist.html',{'data':ob})


def playlist(request):
    ob = playlist_table.objects.all().select_related('song')
    return render(request, 'ADMIN/playlist.html', {'data': ob})



def playlist_delete(request,id):
    a=playlist_table.objects.get(id=id)
    a.delete()
    return redirect('/playlist')



def add_play(request):
    # Fetch all songs
    songs = song_table.objects.all()

    # Get unique emotion values from the database
    emotions = song_table.objects.values_list('emotion', flat=True).distinct()

    # Pass the songs and emotions to the template
    return render(request, 'ADMIN/add play.html', {'songs': songs, 'emotions': emotions})





def add_playlist2_post(request):
    pname = request.POST['pname']
    selected_songs = request.POST.getlist('selected_songs')

    if not selected_songs:
        return HttpResponse('''<script>alert('Please select at least one song');window.location='/add_play'</script>''')

    first_song = song_table.objects.get(id=selected_songs[0])

    existing_playlist = playlist_table.objects.filter(pname=pname).first()

    if existing_playlist:
        playlist = existing_playlist
    else:
        playlist = playlist_table(pname=pname, emotion=first_song.emotion, song=first_song)
        playlist.save()

    # Add all selected songs to the playlist
    for song_id in selected_songs:
        song = song_table.objects.get(id=song_id)

        existing_detail = playlist_details_table.objects.filter(pname=playlist, sname=song).first()

        if not existing_detail:
            playlist_detail = playlist_details_table(pname=playlist, sname=song)
            playlist_detail.save()

    return HttpResponse(
        '''<script>alert('Songs added to playlist successfully');window.location='/playlist'</script>''')


def homepage(request):
    return render(request, 'ADMIN/homepage.html')



def add_play_post(request):
    pname=request.POST['pname']
    sname=request.POST['sname']
    # song=request.FILES['add']
    #
    # fs=FileSystemStorage()
    # fsave=fs.save()

    ob=playlist_table()
    ob.pname=pname
    ob.sname=sname

    ob.save()
    return HttpResponse('''<script>alert('playlist added succesfully`');window.location='/playlist'</script>''')


def edit_play(request,id):
    edit=playlist_table.objects.get(id=id)
    request.session['playlist']=id
    return render(request,'ADMIN/editplay.html',{'data':edit})

def editplay_post(request):
    post=playlist_table.objects.get(id=request.session['playlist'])
    post.pname=request.POST['textfield']
    post.sname=request.POST['textfield2']
    post.save()
    return HttpResponse('''<script>alert('playlist editted succesfully`');window.location='/playlist'</script>''')


# def song(request):
#     ob = song_table.objects.all()
#     return render(request, 'ADMIN/song.html',{'data':ob})


def song(request):
    ob = song_table.objects.all()
    # Get unique emotions for the dropdown filter
    emotions = song_table.objects.values_list('emotion', flat=True).distinct()
    return render(request, 'ADMIN/song.html', {'data': ob, 'emotions': emotions})



def song_delete(request,id):
    a=song_table.objects.get(id=id)
    a.delete()
    return redirect('/song')


def add_song(request):
    return render(request, 'ADMIN/add song.html')

def edit_song(request,id):
    edit=song_table.objects.get(id=id)
    request.session['song']=id
    return render(request,'ADMIN/editsong.html',{'data':edit})


def editsong_post(request):
    post = song_table.objects.get(id=request.session['song'])
    post.sname = request.POST['textfield']
    post.duration = request.POST['textfield2']

    if request.FILES.get('simage'):
        simage = request.FILES['simage']
        post.simage = simage


        # fs = FileSystemStorage()
        # filename = fs.save(simage.name, simage)
        #
        #
        # post.simage = fs.url(filename)   post.simage = simage

    post.save()

    return HttpResponse('''<script>alert('Song edited successfully'); window.location='/song'</script>''')




def add_song_post(request):
    sname = request.POST['sname']
    duration = request.POST['duration']
    emotion = request.POST['emotion']
    song = request.FILES["file"]
    simage = request.FILES.get("simage")

    max_length = song_table._meta.get_field('sname').max_length
    if len(sname) > max_length:
        sname = sname[:max_length]

    if not sname or not duration or not emotion or not song:
        return HttpResponse(
            '''<script>alert('All fields except image are required!');window.location='/add_song'</script>''')


    ob=song_table()
    ob.sname = sname
    ob.duration = duration
    ob.emotion=emotion
    ob.song=song
    ob.simage=simage
    ob.save()
    return HttpResponse('''<script>alert('song added succesfully`');window.location='/song'</script>''')





def feedback(request):
    ob=feedback_table.objects.all()
    return render(request, 'ADMIN/feedback.html',{'data':ob})



def complaint(request):
    ob=complaint_table.objects.all()
    return render(request, 'ADMIN/complaint.html',{'data':ob})

def replay(request,id):
    request.session['cid'] = id
    ob = complaint_table.objects.get(id=id)
    return render(request,'ADMIN/replay.html',{'data':ob})

def complaint_reply_post(request):
    id = request.session['cid']
    compl = complaint_table.objects.get(id=id)
    compl.reply = request.POST['textfield']
    compl.save()
    return HttpResponse('''<script>alert('reply send succesfully`');window.location='/complaint'</script>''')



#--------------------------------------------------------------------------------------------------androoo




def logincode(request):
    print(request.POST)
    un = request.POST['username']
    pwd = request.POST['password']
    print(un, pwd)
    try:
        ob = login_table.objects.get(username=un, password=pwd)

        if ob is None:
            data = {"task": "invalid"}
        else:
            print("in user function")
            data = {"task": "valid", "lid": ob.id,"type":ob.type}
        r = json.dumps(data)
        print(r)
        return HttpResponse(r)
    except:
        data = {"task": "invalid"}
        r = json.dumps(data)
        print(r)
        return HttpResponse(r)

def and_user_registration(request):
    name=request.POST['name']
    email=request.POST['email']
    phone=request.POST['phone']
    pin=request.POST['pin']
    place=request.POST['place']
    post=request.POST['post']
    image=request.FILES['image']
    username=request.POST['username']
    password=request.POST['password']

    fs=FileSystemStorage()
    fsave=fs.save(image.name,image)

    print("========,fsa--",fsave)
    ob=login_table()
    ob.username=username
    ob.password=password
    ob.type="user"
    ob.save()

    obb=user_table()
    obb.LOGIN=ob
    obb.name=name
    obb.place=place
    obb.email = email
    obb.phone = phone

    obb.pin = pin
    obb.post = post
    obb.image=fsave

    obb.save()
    return JsonResponse({'task': 'valid'})





def and_profile(request):
    lid = request.POST.get('lid')
    student = user_table.objects.get(LOGIN_id=lid)
    print(student)
    print(request.POST,'aaaaaaaaaaaaa')
    return JsonResponse(
        {'status': 'ok',
         'name': student.name,
         'email': student.email,
         'phone': str(student.phone),
         'place': student.place,
         'pin': str(student.pin),
         'post': student.post,
         'image': student.image.url[1:]})




def and_editprofile(request):
    lid = request.POST['lid']
    name = request.POST['name']
    email = request.POST['email']
    place = request.POST['place']
    post = request.POST['post']
    pin = request.POST['pin']
    phone = request.POST['phone']



    try:
        profile = user_table.objects.get(LOGIN_id=lid)
    except user_table.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'User not found'})

    profile.name = name
    profile.phone = phone
    profile.place = place
    profile.post = post
    profile.pin = pin
    profile.email = email

    if 'image' in request.FILES:
        image = request.FILES['image']
        fs = FileSystemStorage()
        filename = fs.save(image.name, image)
        profile.image = filename

    profile.save()
    return JsonResponse({'status': 'ok'})

from .models import song_table

from mutagen.mp3 import MP3
from mutagen.id3 import ID3


def get_audio_duration(file_path):
    """Returns the duration of the audio file in seconds"""
    try:
        audio = MP3(file_path, ID3=ID3)
        return audio.info.length  # Returns the duration in seconds
    except Exception as e:
        print(f"Error getting duration: {str(e)}")
        return 0  # If any error occurs, return 0 as a fallback


def play_song(request):
    songs = song_table.objects.all()
    data = []
    for song in songs:
        song_url = request.build_absolute_uri(song.song.url) if song.song else None
        image_url = request.build_absolute_uri(song.simage.url) if song.simage else None

        # Get the song's duration
        song_file_path = song.song.path  # Absolute path to the file
        song_duration = get_audio_duration(song_file_path)  # Get duration
        dur = song_duration/60
        dur_formatted = f"{dur:.2f}"


        data.append({
            'id': song.id,
            'sname': song.sname,
            'emotion': song.emotion,
            'simage': image_url,
            'song': song_url,
            'duration': str(dur_formatted)  # Add the duration to the response data
        })
    for song_data in data:
        print(song_data)
    return JsonResponse({
        'status': 'ok',
        'data': data
    })



def user_sent_feedback(request):
    lid=request.POST['lid']
    content=request.POST['content']
    rating=request.POST['rating']

    a=feedback_table()
    a.USER=user_table.objects.get(LOGIN_id=lid)
    a.date=datetime.now().today().date()
    a.content=content
    a.rating=rating
    a.save()
    return JsonResponse({'status': 'ok'})

def user_send_complaint(request):
    lid=request.POST['lid']
    content=request.POST['content']

    a=complaint_table()
    a.USER=user_table.objects.get(LOGIN_id=lid)
    a.date=datetime.now().today().date()
    a.content=content
    a.reply='pending'
    a.save()
    return JsonResponse({'status': 'ok'})



def user_view_complaint(request):
    lid=request.POST['lid']
    l=[]
    a=complaint_table.objects.filter(USER__LOGIN_id=lid)
    for i in a:
        l.append({'id':i.id,'date':str(i.date),'reply':i.reply,'content':i.content})
    return JsonResponse({'status': 'ok', 'data': l})



def view_user_chat(request):
    lid = request.POST.get('lid')
    l = []

    a = user_table.objects.all().exclude(LOGIN__id=lid)

    for i in a:
        l.append({
            'id': i.id,
            'LOGIN': str(i.LOGIN.id),
            'name': i.name,
            'image': i.image.url[1:] if i.image else '',  # Ensure there's a fallback for image
            'place': i.place
        })
    print(l)

    return JsonResponse({'status': 'ok', 'data': l})



def user_viewchat(request):
    fromid = request.POST["from_id"]
    toid = request.POST["to_id"]
    opposite_person = user_table.objects.get(LOGIN_id=toid)
    name = opposite_person.name
    # Filter and sort the queryset by date and time in ascending order
    res = Chat.objects.filter(Q(FROMID=fromid, TOID=toid) | Q(FROMID=toid, TOID=fromid)).order_by('id')


    l = []

    for i in res:
        l.append({
            "id": i.id,
            "msg": i.message,
            "from": i.FROMID.id,  # Convert to primary key
            "date": i.date.strftime('%Y-%m-%d %H:%M:%S'),  # Format date as a string
            "to": i.TOID.id  # Convert to primary key
        })


    return JsonResponse({"status": "ok", 'data': l,'user':name})






from datetime import datetime

def user_sendchat(request):
    from_id = request.POST['from_id']
    to_id = request.POST['to_id']
    msg = request.POST['message']

    # try:
    if True:
        print(request.POST)
        from_login = login_table.objects.get(pk=from_id)
        to_login = login_table.objects.get(pk=to_id)

        c = Chat()
        c.FROMID = from_login
        c.TOID = to_login
        c.message = msg
        c.date = datetime.now()
        c.save()
        print(c)
        return JsonResponse({'status': "ok"})






from django.shortcuts import render, redirect
from django.contrib import messages  # Add this import
from .models import playlist_table, song_table, playlist_details_table


def add_playlist_get(request, id):
    a = playlist_table.objects.get(id=id)
    aa = playlist_details_table.objects.filter(pname_id=id)

    # Get IDs of songs already in the playlist
    existing_song_ids = aa.values_list('sname_id', flat=True)

    # Filter songs: match emotion and exclude songs already in playlist
    kk = song_table.objects.filter(emotion=a.emotion).exclude(id__in=existing_song_ids)

    request.session['id'] = id
    return render(request, 'ADMIN/playlist name.html', {'data': a, 'emotion': a.emotion, 'aa': aa, "kk": kk})






from django.shortcuts import get_object_or_404, redirect
from django.http import HttpResponse

def add_playlist_post(request, id):
    if request.method == "POST":
        try:
            # Get the playlist
            playlist = get_object_or_404(playlist_table, id=id)

            # Get selected song IDs from the form
            selected_songs = request.POST.getlist('selected_songs')

            if not selected_songs:
                return HttpResponse(
                    f'''<script>alert('No songs selected!');window.location='/add_playlist_get/{id}'</script>''')


            # Add each selected song to the playlist_details_table
            for song_id in selected_songs:
                song = get_object_or_404(song_table, id=song_id)
                # Check if song already exists in playlist to avoid duplicates
                if not playlist_details_table.objects.filter(pname=playlist, sname=song).exists():
                    playlist_details_table.objects.create(
                        pname=playlist,
                        sname=song
                    )

            return HttpResponse(f'''<script>alert('Song(s) added successfully');window.location='/add_playlist_get/{id}'</script>''')

        except Exception as e:
            return HttpResponse(f'''<script>alert('An error occurred: {str(e)}');window.location='/add_playlist_get/{id}'</script>''')

    # If not POST, return error
    return HttpResponse("Method not allowed!", status=405)












def addsongplay(request):
    sid=request.POST['sid']

    return HttpResponse("Song play added successfully!", status=201)


def add_playlist(request):
    pname = request.POST['pname']
    emotion = request.POST['emotion']

    try:
        # Check if a playlist with the given emotion and song exists
        existing_playlist = playlist_table.objects.filter(emotion=emotion, pname=pname).first()

        if existing_playlist:
            # If the playlist exists, add the song to the playlist_details_table
            playlist_detail = playlist_details_table.objects.filter(pname=existing_playlist, sname_id=request.session['id'])
            if not playlist_detail.exists():
                playlist_detail = playlist_details_table(
                    pname=existing_playlist,
                    sname=song_table.objects.get(id=request.session['id'])
                )
                playlist_detail.save()
            return HttpResponse('''<script>alert(' succesfully`');window.location='/song'</script>''')

        # If the playlist does not exist, create a new playlist in playlist_table
        new_playlist = playlist_table(
            pname=pname,
            emotion=emotion,
            song=song_table.objects.get(id=request.session['id'])
        )
        new_playlist.save()

        # Add the song to the playlist_details_table
        playlist_detail = playlist_details_table(
            pname=new_playlist,
            sname=song_table.objects.get(id=request.session['id'])
        )
        playlist_detail.save()

        return HttpResponse('''<script>alert('Added succesfully`');window.location='/song'</script>''')

    except Exception as e:
        return HttpResponse('''<script>alert('rerror occured`');window.location='/song'</script>''')




def add_song_playlist(request,id):
    p=playlist_table.objects.get(id=id)
    a_emotion=p.emotion
    print(a_emotion)

    return render(request, 'ADMIN/playlist name.html')


def playlistsong_delete(request,id):
    a=playlist_details_table.objects.get(id=id)
    a.delete()
    return redirect('/add_playlist_get')


def playlistsong_delete(request, id):
    playlist_song = playlist_details_table.objects.get(id=id)
    pdid = playlist_song.pname_id
    playlist_song.delete()

    return redirect('/add_playlist_get/' + str(pdid))


import os

def uploadimage(request):
    print(request.FILES)
    try:
        os.remove(r"C:\Users\mrfaa\PycharmProjects\music\media\s.jpg")
    except FileNotFoundError:
        pass

    if 'image' not in request.FILES:
        return HttpResponse(json.dumps({"error": "No image uploaded"}), content_type="application/json")

    f = request.FILES['image']
    fs = FileSystemStorage()
    image_path = fs.save("s.jpg", f)
    full_image_path = os.path.join(fs.location, image_path)

    emotion_detected = camclick(full_image_path)
    print(emotion_detected, "Detected Emotion")




    # with open(r"C:\Users\mrfaa\PycharmProjects\music\myfile.txt", "w") as file1:
    with open(r"C:\Users\mrfaa\PycharmProjects\123\music\myfile.txt", "w") as file1:
        file1.write(emotion_detected or "No Face Detected")
    ob = song_table.objects.filter(emotion=emotion_detected)

    l = []
    for i in ob:
        l.append({
            'id': i.id,
            'pname': i.sname,
            'simage': i.simage.url,
            'song': i.sname,
            'emotion': i.emotion,
        })
    print(l)

    data = {'status': "ok","data":l,"emotion": emotion_detected or "No Face Detected"}


    return HttpResponse(json.dumps(data), content_type="application/json")








def viewplaylist_emo(request):
    emo=request.POST['emotion']
    print (emo,"hhhhhhhhhhhhhhhhhhhhhhhhhhh")
    complaint_obj = song_table.objects.filter(emotion=emo)
    l = []
    for i in complaint_obj:
        l.append({
            'id': i.id,
            'song': str(i.sname),
            'song_f': str(i.song.url)[1:],
            'simage': i.simage.url[1:],
        })
    print(l)

    return JsonResponse({'status': 'ok', 'data': l,"emotion":emo})




def view_playlistapp(request):
    a=playlist_table.objects.all()
    l=[]
    for i in a:
        l.append({
            'id':i.id,
            'pname':i.pname,
            'simage': i.song.simage.url,
            'song':i.song.sname,
            'emotion':i.emotion,
        })
    print(l)


    return JsonResponse({'status':'ok','data':l})




def view_playlistapp_details(request):
    pid=request.POST['pid']
    a=playlist_details_table.objects.filter(pname_id=pid)
    l=[]
    for i in a:
        l.append({
            'id':i.id,
            'sname':i.sname.sname,
            'simage':i.sname.simage.url,
            'emotion':i.sname.emotion,
            'duration':i.sname.duration,
            'song':i.sname.song.url,

        })
    print(l)


    return JsonResponse({'status':'ok','data':l})


def cryptophotoupload (request):
    image=request.FILES['image']
    fs=FileSystemStorage()
    path=fs.save(image.name,image)

    aa = camclick(r"C:\Users\mrfaa\PycharmProjects\123\music\media")


    return JsonResponse({'status':'ok'})





def liked_song(request):
    lid = request.POST['lid']
    sid = request.POST['sid']

    play = liked_playlist.objects.filter(USER__LOGIN_id=lid, song__id=sid)

    if play.exists():
        play.delete()
        return JsonResponse({'status': 'removed'})
    else:
        a = liked_playlist()
        a.USER = user_table.objects.get(LOGIN_id=lid)
        a.song = song_table.objects.get(id=sid)
        a.save()
        return JsonResponse({'status': 'ok'})




import json
from django.http import JsonResponse






def get_liked_songs(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)  # Parse JSON body
            lid = data.get('lid')  # Extract 'lid'

            if not lid:
                return JsonResponse({"error": "Missing lid"}, status=400)

            # Get the absolute URL prefix for media files
            protocol = 'https' if request.is_secure() else 'http'
            host = request.get_host()
            base_url = f"{protocol}://{host}"

            # Get all song IDs liked by this user
            liked_songs = liked_playlist.objects.filter(USER__LOGIN_id=lid)

            songs_list = []
            for i in liked_songs:
                # Make sure we have complete URLs for song and image
                song_url = i.song.song.url
                if not song_url.startswith('http'):
                    song_url = f"{base_url}{song_url}"

                image_url = None
                if i.song.simage:
                    image_url = i.song.simage.url
                    if not image_url.startswith('http'):
                        image_url = f"{base_url}{image_url}"

                songs_list.append({
                    'id': i.song.id,  # Make sure we use song.id, not the liked_playlist id
                    'emotion': i.song.emotion,
                    'sname': i.song.sname,
                    'duration': i.song.duration,
                    'song': song_url,
                    'simage': image_url
                })

            return JsonResponse({'liked_songs': songs_list}, safe=False)

        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)
        except Exception as e:
            # Log the error and return a helpful message
            print(f"Error in get_liked_songs: {str(e)}")
            return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({"error": "Invalid request method"}, status=405)