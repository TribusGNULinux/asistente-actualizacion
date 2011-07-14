#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import gobject
import pynotify
import subprocess


def foo_cb(n, action):
       print "INICIAR ACTUALIZACION"
       subprocess.Popen(["gksu","asistente-actualizacion"])
       n.close()
       loop.quit()

def reboot_cb(n, action):
       print "REINICIAR"
       subprocess.Popen(["gksu","reboot"])
       n.close()
       loop.quit()


def default_cb(n, action):
       print "NO PASA NADA"
       n.close()
       loop.quit()

def default_cb2(n, action):
       check_cb_conf=open(os.environ['HOME']+"/.config/asistente.conf","w")
       check_cb_conf.write("MOSTRAR=0")
       check_cb_conf.close()
       n.close()
       loop.quit()

if __name__ == '__main__':

       try:
           check_cb_conf=open(os.environ['HOME']+"/.config/asistente.conf","r")
           mostrar=check_cb_conf.readline()
       except:
           mostrar=""


       try:
           check_cb_conf=open("/usr/share/asistente-actualizacion/paso.conf","r")
           paso=check_cb_conf.readline()
           check_cb_conf.close()
       except:
           paso=""
       print paso
       pynotify.init ("Asistente Actualización")
       loop = gobject.MainLoop ()
       n = pynotify.Notification("Fin de la actualización", "Debe reiniciar para finalizar la actualización")
       n.set_timeout (pynotify.EXPIRES_NEVER)
       n.add_action ("blah", "Reiniciar", reboot_cb)
       n.show()
       loop.run()