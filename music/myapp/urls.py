from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from myapp import views

urlpatterns = [
    path('', views.login, name='login'),
    path('login_post', views.login_post, name='login_post'),
    path('add_play_post', views.add_play_post, name='add_play_post'),
    path('add_playlist2_post', views.add_playlist2_post, name='add_playlist2_post'),
    path('admin_view', views.admin_view, name='admin_view'),
    path('view_user', views.view_user, name='view_user'),
    path('playlist', views.playlist, name='playlist'),
    path('add_play', views.add_play, name='add_play'),
    path('song', views.song, name='song'),
    path('add_song', views.add_song, name='add_song'),
    path('add_song_post', views.add_song_post, name='add_song_post'),
    path('feedback', views.feedback, name='feedback'),
    path('complaint', views.complaint, name='complaint'),
    path('complaint_reply_post', views.complaint_reply_post, name='complaint_reply_post'),
    path('replay/<id>', views.replay, name='replay'),
    path('playlist_delete/<id>', views.playlist_delete, name='playlist_delete'),
    path('song_delete/<id>', views.song_delete, name='song_delete'),
    path('edit_play/<id>', views.edit_play, name='edit_play'),
    path('edit_song/<id>', views.edit_song, name='edit_song'),
    path('editsong_post', views.editsong_post, name='editsong_post'),
    path('editplay_post', views.editplay_post, name='editplay_post'),
    path('homepage.html', views.homepage, name='homepage'),


    path('add_playlist', views.add_playlist, name='add_playlist'),
    path('add_playlist_get/<id>', views.add_playlist_get, name='add_playlist_get'),
    path('add_playlist_post/<id>', views.add_playlist_post, name='add_playlist_post'),
    path('add_song_playlist/<id>', views.add_song_playlist, name='add_song_playlist'),
    path('view_playlistapp', views.view_playlistapp, name='view_playlistapp'),
    path('playlistsong_delete/<id>', views.playlistsong_delete, name='playlistsong_delete'),


    path('logincode', views.logincode, name='logincode'),
    path('viewplaylist_emo', views.viewplaylist_emo, name='viewplaylist_emo'),
    path('/uploadimage', views.uploadimage, name='uploadimage'),
    path('and_user_registration', views.and_user_registration, name='and_user_registration'),
    path('and_profile', views.and_profile, name='and_profile'),
    path('and_editprofile', views.and_editprofile, name='and_editprofile'),
    path('play_song', views.play_song, name='play_song'),
    path('user_sent_feedback', views.user_sent_feedback, name='user_sent_feedback'),
    path('user_send_complaint', views.user_send_complaint, name='user_send_complaint'),
    path('user_view_complaint', views.user_view_complaint, name='user_view_complaint'),
    path('view_user_chat', views.view_user_chat, name='view_user_chat'),
    path('user_viewchat', views.user_viewchat, name='user_viewchat'),
    path('user_sendchat', views.user_sendchat, name='user_sendchat'),

    path('view_playlistapp_details', views.view_playlistapp_details, name='view_playlistapp_details'),
    path('/liked_song', views.liked_song, name='liked_song'),
    path('/get_liked_songs', views.get_liked_songs, name='get_liked_songs'),
]+ static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
