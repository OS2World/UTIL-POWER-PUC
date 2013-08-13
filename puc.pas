//
//  Parallelport Usv/Ups Control  (read from any port)
//
//  by Denny Mleinek, Year 2001, It's ALL FREE !, Use on your OWN RISK ! 
//  
//  Designed and compiled under Virtual Pascal/2...
//

program PUC;
uses Crt, Dos, Use32;

type 

 tUSVStatus = ( BadPort, Disconnect, Online, OnAkku, OnAkkuDown );

var

 Status : tUSVStatus;

 key : char;                    // falls mal was von der Tastatur kommt 

 port1 : word;                  // die portvariable die auszulesen ist 

 delay1 : longint;              // kleine pause zwischen dem lesen des ports 

 portwert,                      // die variablen die den portstatus und die vergleichswerte aufnehmen 
 oldwert,
 brokencabel,
 normal,
 akkupower,
 akkudown  : byte;
 
 exitforced,                    // f„ngt erstes ESC ab: ESC,ESC = Exit
 changed : boolean;             // wenn sich der portwert <> oldwert ge„ndert hat = true 
 
 timer, 
 BadPortTimer, 
 DiscTimer, 
 OnlineTimer, 
 OnAkkuTimer, 
 TimeOutTimer,
 OnAkkuDownTimer   : longint;   // z„hlervariablen fr zeitsteuerung
 
 DiscCommand,
 OnlineCommand,
 OnAkkuCommand,
 OnAkkuDownCommand : string;    // variablen die die cmd-pathe aufnehmen

 ExitBeep,
 DiscBeep,
 OnAkkuBeep,
 OnAkkuDownBeep : boolean;      // statusvariablen ob beept”ne oder nicht
 
 DiscTimeOut,
 OnlineTimeOut,
 OnAkkuTimeOut,
 OnAkkuDownTimeOut : longint;   // timeout variablen fr command steuerung
 


 function z2s(sr:word):string;VAR sr2:string; Begin Str(sr,sr2);                                // zahl zu string
          if length(sr2)=1 then sr2:='0'+sr2; z2s:=sr2; end;

 function gettimestr:string; Var st,min,sec,hsec : word; t : string; Begin
          gettime(st,min,sec,hsec); t:=z2s(st)+':'+z2s(min)+':'+z2s(sec); gettimestr:=t;        // zeit string
        End;

 function getdatestr:string; Var ta,mon,ja,dow : word; d : string; Begin                        // datum string
          getdate(ja,mon,ta,dow); d:=z2s(ta)+'.'+z2s(mon)+'.'+z2s(ja); getdatestr:=d;
         End;
    
 function zeitstr:string; var s:string; Begin zeitstr:=gettimestr; {s:=getdatestr+'/'+gettimestr; delete(s,7,2); zeitstr:=s;} End;

 function run(cmd:string):boolean; Begin ExecFlags := efASync; Exec(GetEnv('COMSPEC'), '/C Start '+cmd);  End;

 procedure Say(msg:string);                                                          // write and log MSG-Text
 Var l : text; 
 Begin
  Writeln(zeitstr+'> '+msg);
  Assign(l,'puc.log'); filemode:=$0001;
  {$i-} Append(l); {$i-} if ioresult<>0 then Rewrite(l);
  writeln(l,getdatestr+'/'+zeitstr+'> '+msg);
  Close(l);
 End;

 function ReadCfg:boolean; Var f : text; r : string; code : integer;                    //  Config (PUC.CFG) auslesen
  procedure badcfg(msg:string); Begin Say(msg); Close(f); Exit; End;
 Begin
  ReadCfg:=False; Assign(f,'PUC.CFG'); filemode:=$0000; {$i-} Reset(f); {$i+}
  if ioresult<>0 then Exit;
  while not eof(f) do begin readln(f,r);
   if copy(r,1,5)='PORT=' then begin Val(copy(r,6,255),port1,code); if code>0 then BadCfg('Error: Port');  end;
   if copy(r,1,6)='DELAY=' then begin Val(copy(r,7,255),delay1,code); if code>0 then BadCfg('Error: Delay'); end;      
   
   if copy(r,1,5)='DISC=' then begin Val(copy(r,6,255),brokencabel,code); if code>0 then BadCfg('Error: DISC'); end;
   if copy(r,1,7)='ONLINE=' then begin Val(copy(r,8,255),normal,code); if code>0 then BadCfg('Error: ONLINE'); end;      
   if copy(r,1,7)='ONAKKU=' then begin Val(copy(r,8,255),akkupower,code); if code>0 then BadCfg('Error: OnAkku'); end;         
   if copy(r,1,11)='ONAKKUDOWN=' then begin Val(copy(r,12,255),akkudown,code); if code>0 then BadCfg('Error: OnAkkuDown'); end;         
   
   if copy(r,1,8)='DISCCMD=' then begin DiscCommand:=copy(r,9,255); end;
   if copy(r,1,10)='ONLINECMD=' then begin OnlineCommand:=copy(r,11,255); end;
   if copy(r,1,10)='ONAKKUCMD=' then begin OnAkkuCommand:=copy(r,11,255); end;
   if copy(r,1,14)='ONAKKUDOWNCMD=' then begin OnAkkuDownCommand:=copy(r,15,255); end;

   if copy(r,1,12)='DISCTIMEOUT=' then begin Val(copy(r,13,255),disctimeout,code); if code>0 then BadCfg('Error: DiscTimeOut'); end;
   if copy(r,1,14)='ONLINETIMEOUT=' then begin Val(copy(r,15,255),onlinetimeout,code); if code>0 then BadCfg('Error: OnlineTimeOut'); end;
   if copy(r,1,14)='ONAKKUTIMEOUT=' then begin Val(copy(r,15,255),onakkutimeout,code); if code>0 then BadCfg('Error: OnAkkuTimeOut'); end;   
   if copy(r,1,18)='ONAKKUDOWNTIMEOUT=' then begin Val(copy(r,19,255),onakkudowntimeout,code); if code>0 then BadCfg('Error: OnAkkuDownTimeOut'); end;   
   
   if copy(r,1,8)='EXITBEEP' then begin Exitbeep:=true; end;
   if copy(r,1,8)='DISCBEEP' then begin DiscBeep:=true; end; 
   if copy(r,1,10)='ONAKKUBEEP' then begin OnAkkuBeep:=true; end;
   if copy(r,1,14)='ONAKKUDOWNBEEP' then begin OnAkkuDownBeep:=true; end;
  end;
  Close(f);
  ReadCfg:=True;
 End;

 procedure GetStatus; 
 Begin
  portwert:=port[port1];
  if portwert=oldwert then changed:=false else changed:=true;
  if portwert = brokencabel then Status:=DisConnect else
  if portwert = normal      then Status:=Online else
  if portwert = akkupower   then Status:=OnAkku else  
  if portwert = akkudown    then Status:=OnAkkuDown else Status:=BadPort;  
  oldwert:=portwert;       
 End;



  // ------------------------------------------ P U C - Start ------------------------------------------------------- //

BEGIN                   // Initalisierung

  EXITBEEP:=false; DISCBEEP:=false; ONAKKUBEEP:=false; ONAKKUDOWNBEEP:=false;
  exitforced:=false; timer:=0; TimeOutTimer:=0; BadPortTimer:=0; DiscTimer:=0; OnlineTimer:=0; OnAkkuTimer:=0; OnAkkuDownTimer:=0;

  Say(''); clrscr;
  writeln(' PUC / Parallelport-USV-Control, [ESC,ESC] = Exit, Start at '+getdatestr+'/'+gettimestr);
  textcolor(14); textbackground(1); 
  window(2,2,79,24); clrscr; window(3,3,78,23); clrscr;
  Say('Starting PUC, read cfg and portaddress...');
  if ReadCfg=false then Begin Say('PUC.CFG not found !'); halt; End;
  Say('Delay: '+z2s(delay1)+'  Port: '+z2s(port1)+'  Disc: '+z2s(brokencabel)+'  On: '+z2s(normal)+'  Akku: '+z2s(akkupower)+'  Down: '+z2s(akkudown));
  

  if paramstr(1)='test' then begin                                                    // Read Port Test
                              writeln; writeln('Break with CTRL + C'); writeln;
                              repeat
                               getstatus; writeln(zeitstr,'>  ',portwert);
                               delay(700);
                              until key=#255; 
                             end;   

 
  // --------------------------------------erstmaliges auslesen etc.------------------------------------------------ //
 
  getstatus; 
  
  if Status = BadPort then begin Say('Portvalue out of range ! Value: '+z2s(portwert)+', Port: '+z2s(port1)+' (dez.)'); end;
  if Status = DisConnect then begin Say('PUC is disconnected from your USV ! Check cable connection.'); end;
  if Status = Online then begin Say('USV Connected, Idle...'); end;
  if Status = OnAkku then begin Say('USV Connected, Warning - USV is in battery mode !'); end;
  if Status = OnAkkuDown then begin Say('USV Connected, Warning - USV is in battery mode and bat. is low !'); end;

  // --------------------------------------------------2xRepeat-Loop------------------------------------------------ //

repeat
 if key=#27 then exitforced:=true;
 repeat

  delay(delay1);
  getstatus; 
 
  if changed=true then                                          // Aktionen wenn sich der PortWert ge„ndert hat 
  begin
   if Status = BadPort    then Say('Portvalue out of range ! Value: '+z2s(portwert)+', Port: '+z2s(port1)+' (dez.)');
   if Status = DisConnect then Say('Switching to "Disconnected", Warning - check cable connection.');
   if Status = Online     then Say('Switching to "Online", Idle...');
   if Status = OnAkku     then Say('Switching to "OnAkku", Warning - USV is in battery mode !');
   if Status = OnAkkuDown then begin Say('Switching to "OnAkkuDown", Warning - USV is in battery mode'); 
                                     Say('          and battery is low !!!'); end;
   timer:=0; BadPortTimer:=0; DiscTimer:=0; OnlineTimer:=0; OnAkkuTimer:=0; OnAkkuDownTimer:=0;
  end;

                                                                // Aktionen die bei jedem loop notwendig sind

  if Status = BadPort    then begin PlaySound(500,300); inc(BadPortTimer); end;
  if Status = DisConnect then begin 
                                inc(DiscTimer);
                                if DiscBeep=true then PlaySound(1000,1000); 
                                if DiscTimer=DiscTimeOut then Run(DiscCommand);
                               end;
  if Status = Online     then begin 
                                inc(OnlineTimer); 
                                if OnlineTimer=OnlineTimeOut then Run(OnlineCommand);
                                end;
  if Status = OnAkku     then begin 
                                inc(OnAkkuTimer); 
                                if OnAkkuBeep=true then PlaySound(1000,1000); 
                                if OnAkkuTimer=OnAkkuTimeOut then Run(OnAkkuCommand);
                               end;
  if Status = OnAkkuDown then begin 
                                inc(OnAkkuDownTimer); 
                                if OnAkkuDownBeep=true then begin PlaySound(2000,400); PlaySound(500,400); end;
                                if OnAkkuDownTimer=OnAkkuDownTimeOut then Run(OnAkkuDownCommand);
                               end;
  
  inc(timer);

 until keypressed;
 key:=readkey;
until (key=#27)AND(exitforced=true);     // Beenden wenn ESC,ESC 
                                                               

                // Done, Fertig, Ende, Fin, GameOver...
 Say('Done.');                                                 
 if ExitBeep=true then begin PlaySound(1600,100); PlaySound(600,200); PlaySound(1200,100); end;
 
END.

