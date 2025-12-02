from Tkinter import *
import Tkinter
import random
import threading

num1=random.randint(0,9)
num2=random.randint(0,9)

columnFont = (None,200)
root = Tkinter.Tk()
w=root.winfo_screenwidth()
h=root.winfo_screenheight()
root.geometry("%dx%d"%(w,h))
#root.attributes("-topmost",True)
#root.overrideredirect(True)
maincanvas=Canvas(root,width=w,height=h)
maincanvas.pack()
maincanvas.create_rectangle(0,0,w/3,h,fill='red')
maincanvas.create_rectangle(w/3,0,w*2/3,h,fill='green')
maincanvas.create_rectangle(2*w/3,0,w,h,fill='blue')

maincanvas.create_text((w/6-100),h/2,text=num1,font=columnFont,fill='black',anchor=W,justify=CENTER)
maincanvas.create_text((w/2-100),h/2,text="+",font=columnFont,fill='black',anchor=W,justify=CENTER)
maincanvas.create_text((w/6+2*w/3-100),h/2,text=num2,font=columnFont,fill='black',anchor=W,justify=CENTER)

def keyevent(event):
	sum=input("sum:")
	print("press:"+event.char)
	return(event.char)
def result(sum):
	while True:	
		sum=input("sum:")
		if int(sum) == int(num1)+int(num2):
			print("pass")
			root.quit()
			break
		else:
			print("fail")
			root.quit()
			break
	#root.destroy()
	#root.quit()

#maincanvas.bind(result)

#t=threading.Thread(target=result, args=(sum,))
#t.setDaemon(True)
#t.start()
root.mainloop()


