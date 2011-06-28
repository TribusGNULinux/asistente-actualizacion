#!/usr/bin/python
import threading
import gtk
import random
import time

import gtk, gtk.glade
import os
from multiprocessing import Process

gtk.gdk.threads_init()

NUM_THREADS = 5

class PyApp(gtk.Window):
    def __init__(self, threads=None):
        super(PyApp, self).__init__()
        
        self.glade = gtk.glade.XML("dialogo1.glade")
        self.glade.signal_autoconnect(self)
        self.dialogo=self.glade.get_widget("window1")
        self.trabajando=self.glade.get_widget("trabajando")
        self.trabajando0=self.glade.get_widget("trabajando0")
        self.progreso=self.glade.get_widget("progreso")
        self.trabajando.set_text("Hola1")
        self.trabajando0.set_text("Hola1")
        self.progreso.set_text("Hola1")        
        self.dialogo.show_all()
        self.__create_trayicon()
        self.showed = True

        self.t=ProgressThread(self.trabajando,self.trabajando0,self.progreso)

    def actualizar(self,dialogo):
        self.trabajando=self.glade.get_widget("trabajando")
        self.trabajando.set_text("Hola")



    def load_image(self, path, pixbuf=False):
        img_path = os.path.realpath(os.path.join(os.path.dirname(__file__),
            path))
        pix = gtk.gdk.pixbuf_new_from_file(img_path)
        if pixbuf: return pix
        avatar = gtk.Image()
        avatar.set_from_pixbuf(pix)
        del pix
        return avatar
 
    def __create_trayicon(self):
        if gtk.check_version(2, 10, 0) is not None:
            log.debug("Disabled Tray Icon. It needs PyGTK >= 2.10.0")
            return
        self.tray = gtk.StatusIcon()
        self.tray.set_from_pixbuf(self.load_image('turpial-tray.png', True))
        self.tray.set_tooltip('Asistente Actualizacion')
        self.tray.connect("activate", self.__on_trayicon_click)

    def __on_trayicon_click(self, widget):
        if self.showed:
            self.showed = False
            self.dialogo.hide()
        else:
            self.showed = True
            self.dialogo.show()
         

    def on_window1_delete_event(self, widget, event):
        gtk.main_quit()
 
    def on_button1_clicked(self, widget):
        gtk.main_quit()        

class ProgressThread(threading.Thread):
    def __init__(self,trabajando,trabajando0,progressbar):
        threading.Thread.__init__ (self)

        self.tb = trabajando
        self.tb0 = trabajando0        
        self.pb = progressbar
        
        self.stopthread = threading.Event()

    def run(self):
        while not self.stopthread.isSet():
            gtk.gdk.threads_enter()
            uno=open("msjprogreso","r")
            lineasuno=uno.readlines()
            self.pb.set_text(lineasuno[len(lineasuno)-1][:-1])
            uno.close()

            uno=open("progreso","r")
            lineasuno=uno.readlines()
            self.tb0.set_fraction(float(lineasuno[len(lineasuno)-1])/100)
            uno.close()

            uno=open("uno","r")
            lineasuno=uno.readlines()
            self.tb.set_text(lineasuno[len(lineasuno)-1][:-1])
            uno.close()

            uno=open("dos","r")
            lineasuno=uno.readlines()
            self.tb0.set_text(lineasuno[len(lineasuno)-1][:-1])
            uno.close()


            gtk.gdk.threads_leave()
            
            time.sleep(1)
        
    def stop(self):
        self.stopthread.set()
        
if __name__ == "__main__":
    pyapp = PyApp()
    
    pyapp.t.start()
    
    gtk.gdk.threads_enter()
    gtk.main()
    gtk.gdk.threads_leave()


