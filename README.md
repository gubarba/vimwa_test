# vimwa_test
testing vimwa

Before getting started: if you wish to use VIMWA with an external display, the display should be connected before configuring displays.

first, clone the project on you home directory

Setting the Machine

Setting the workdir and sourcing the vimwa.sh script  
```echo -e "cd ~/vimwa_test >> ~/.bashrc"```
```echo -e "source ~/vimwa_test/vimwa.sh"```  
  


Setting up VIMWA

```cd vimwa_test```  
```source vimwa.sh```  
```deps_install```  
```configure```  
First, you should set up the displays ( and do it again whenever you want to set up a different display configuration), this allows you to enable/disable attached displays (internal and external)  
  
Then, you should set the resources, You must do this step every time you want to change the resources, number of rows and collumns or have changed the display settings (MUST DO IT)  
  
The resources list should be in a file. (defaults to urls.txt)  

  
After exiting the configuration script, it's time to overwrite the ~/.xinitrc file. you can do it easily with the following command.  
```overwrite_xinit```  
  
If everything went right, running the Xserver should work  
```startx```  
  
  
  

After everything is working right, you may want to auto-login and auto-start  
(if you have problems, you can always change the tty with ctrl+alt+F2 , login and use ```kill_vimwa``` to stop the appliance.)  
  
  
If you wish to auto-login and startx (must have overwritten ~/.xinitrc) you must install NODM
Just run the commands as follows  
  
  
```ln -s .xinitrc .xsession```  
the nodm app uses the user .xsession when starting the xserver, that's the point of this symbolic link  
  
  
```sudo apt-get install nodm```  
```sudo nano /etc/default/nodm```  
  
EDIT THE FOLLOWING LINES  
  
        NODM_ENABLED=true  
        NODM_USER=quero  

now rebooting should auto-start vimwa  
