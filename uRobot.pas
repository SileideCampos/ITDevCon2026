unit uRobot;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Colors, FMX.Objects, IdBaseComponent, IdGlobal,
  IdComponent, IdUDPBase, IdUDPClient, System.Threading, FMX.Edit,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
  TRobotCommand = packed record
    Command: Byte;                      // 1 Byte : ID do comando (1=Stop, 2=Frente, 3=Trás, 4=Esq, 5=Dir)
    Speed: Byte;                       // 1 Byte : Velocidade / PWM (0 a 255)
    Time: Word;
  end;

  TForm1 = class(TForm)
    cRigth: TCircle;
    cForward: TCircle;
    cLeft: TCircle;
    cBack: TCircle;
    time: TAlphaTrackBar;
    speed: TTrackBar;
    Switch1: TSwitch;
    btnA1: TButton;
    UDP: TIdUDPClient;
    Edit1: TEdit;
    Edit2: TEdit;
    Memo1: TMemo;
    lblSpeed: TLabel;
    lblTime: TLabel;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button1: TButton;
    Button5: TButton;
    Button6: TButton;
    Timer1: TTimer;
    procedure btnA1Click(Sender: TObject);
    procedure Switch1Click(Sender: TObject);
    procedure DefaultMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    procedure cForwardMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure cBackMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure cRigthMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormCreate(Sender: TObject);
    procedure cLeftMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure speedTracking(Sender: TObject);
    procedure timeChange(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    procedure Button6Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FIsMoving: Boolean;
    procedure EnviarEstrategiaCombate;
    procedure SendCommand(pCommand, pSpeed: Byte; pTime: Word);
    procedure parar;
    procedure ActionTTask(pCommand: Byte);
    procedure ExecutarWheelieSustentado;
    procedure ExecutarWheeliePendulo;

    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  FTaskCommand: ITask;

implementation

{$R *.fmx}

procedure TForm1.FormCreate(Sender: TObject);
begin
  lblSpeed.Text := speed.Value.ToString;
  lblTime.Text := time.Value.ToString;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  if (KeyChar = 'w') then
  begin
    FIsMoving := True;
    Timer1.Enabled := True;
  end;

  if (KeyChar = 'W') then
  begin
    FIsMoving := True;
    ActionTTask(1);
  end;

  if (KeyChar = 'S') then
  begin
    ActionTTask(2);
  end;

  if (KeyChar = 'A') then
  begin
    FIsMoving := True;
    ActionTTask(4);
  end;

  if (KeyChar = 'D') then
  begin
    FIsMoving := True;
    ActionTTask(3);
  end;

 { if (Key = 'D') and not FKeyDPressed then
  begin
    FKeyDPressed := True;
    FIsMoving := True;
    ActionTTask(3, trunc(speed.Value), trunc(time.Value));
  end;
  }
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  if KeyChar = 'w' then
  begin
    FIsMoving := False;
    Timer1.Enabled := False;
  end;

  if CharInSet(KeyChar, ['W','S','A','D']) then
  begin
    FIsMoving := False;
    parar;
  end;
end;

procedure TForm1.Switch1Click(Sender: TObject);
begin
  UDP.Host := edit1.Text;
  UDP.Port := StrToIntDef(Edit2.Text, 0);
  UDP.Connect;
end;

procedure TForm1.timeChange(Sender: TObject);
begin
  lblTime.Text := FloatToStr(time.Value);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if FIsMoving then
  begin
    // Como estamos na Main Thread, lemos o componente diretamente e sem travar
    //SendCommand(1, TRUNC(speed.Value), TRUNC(time.Value));
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  lPacket: TRobotCommand;
  lData: TIdBytes;
begin
  lPacket.Command := 2;
  lPacket.Speed := 255;
  lPacket.Time := 200;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;
  sleep(20);

  lPacket.Command := 2;
  lPacket.Speed := 255;
  lPacket.Time := 300;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;
  sleep(20);

  lPacket.Command := 1;
  lPacket.Speed := 255;
  lPacket.Time := 400;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  lPacket: TRobotCommand;
  lData: TIdBytes;
begin
  parar;
  sleep(100);

  lPacket.Command := 1;
  lPacket.Speed := 255;
  lPacket.Time := 300;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  lPacket.Command := 2;
  lPacket.Speed := 200;
  lPacket.Time := 80;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;

  lPacket.Command := 1;
  lPacket.Speed := 255;
  lPacket.Time := 80;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;
  lPacket.Command := 2;
  lPacket.Speed := 120;
  lPacket.Time := 80;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  ExecutarWheelieSustentado;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  parar;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ExecutarWheeliePendulo;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  commands: array[0..6] of TRobotCommand;
begin
  //re(255);
  //delay(120);
  commands[0].Command := 2;
  commands[0].Speed := 255;
  commands[0].Time := 0;

  commands[1].Command := 1;
  commands[1].Speed := 255;
  commands[1].Time := 0;

  UDP.SendBuffer(RawToBytes(commands[0], SizeOf(commands[0])));
  sleep(1200);

  //stop();
  //delay(40);
  //parar;
  //sleep(400);

  //frente(255);
  //delay(250); // Tempo que ele segura a frente levantada

  UDP.SendBuffer(RawToBytes(commands[1], SizeOf(commands[1])));
  sleep(2500);

  //stop();
  parar;
end;

procedure TForm1.EnviarEstrategiaCombate;
begin
  TTask.Run(
    procedure
    var
      commands: array[0..6] of TRobotCommand;
    begin
      // Andar para trás por 500ms
      commands[0].Command := 2;
      commands[0].Speed := 255;
      commands[0].Time := 200;

      UDP.SendBuffer(RawToBytes(commands[0], SizeOf(commands[0])));
      parar;
      sleep(5000);

      // Virar à direita por 200ms
      commands[1].Command := 3;
      commands[1].Speed := 255;
      commands[1].Time := 320;

      UDP.SendBuffer(RawToBytes(commands[1], SizeOf(commands[1])));
      parar;
      sleep(5000);

      // Andar para a frente por 800ms
      commands[2].Command := 1;
      commands[2].Speed := 255;
      commands[2].Time := 200;

      UDP.SendBuffer(RawToBytes(commands[2], SizeOf(commands[2])));
      parar;
      sleep(5000);

      // Virar à esquerda por 200ms
      commands[3].Command := 4;
      commands[3].Speed := 255;
      commands[3].Time := 350;

      UDP.SendBuffer(RawToBytes(commands[3], SizeOf(commands[3])));
      parar;
      sleep(5000);

      // Andar para a frente por 800ms
      commands[4].Command := 1;
      commands[4].Speed := 255;
      commands[4].Time := 400;

      UDP.SendBuffer(RawToBytes(commands[4], SizeOf(commands[4])));
      parar;
      sleep(5000);

      // Virar à esquerda por 200ms
      commands[5].Command := 4;
      commands[5].Speed := 255;
      commands[5].Time := 360;

      UDP.SendBuffer(RawToBytes(commands[5], SizeOf(commands[5])));
      parar;
      sleep(5000);

      // Andar para a frente por 800ms
      commands[6].Command := 1;
      commands[6].Speed := 255;
      commands[6].Time := 500;

      UDP.SendBuffer(RawToBytes(commands[6], SizeOf(commands[6])));
      parar;
      sleep(5000);

      //lData := RawToBytes(commands, SizeOf(commands));

      // Dispara o lote inteiro em um único pacote UDP
      //UDP.SendBuffer(lData);
    end
  );
end;

procedure TForm1.ExecutarWheelieSustentado;
var
  lPacket: TRobotCommand;
  lData: TIdBytes;
begin
  // 1. Garante que começa parado
  parar;
  Sleep(50);

  // 2. Dá o recuo rápido para ganhar inércia (Command = 2, Ré)
  lPacket.Command := 2;
  lPacket.Speed := 255;
  lPacket.time := 100; // Ajuste o tempo bruto (multiplicado por 10ms na ESP)
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);
  //Sleep(150);

  parar;
  Sleep(20);

  // 3. O "Soco" explosivo para frente (Command = 1, Frente)
  lPacket.Command := 1;
  lPacket.Speed := 255;
  lPacket.time := 250;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  // 4. Fase de Sustentação / Pulsos para segurar equilibrado
  // Pulso 1 de apoio
  lPacket.Command := 1;
  lPacket.Speed := 210;
  lPacket.time := 50;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);
  //Sleep(50);

  // Pulso 2 de apoio
  lPacket.Command := 1;
  lPacket.Speed := 180;
  lPacket.time := 50;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);
  //Sleep(50);

  // Pulso 3 de sustentação
  lPacket.Command := 1;
  lPacket.Speed := 200;
  lPacket.time := 80;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);
  //Sleep(80);

  // 5. Pouso suave (ré bem curta para a rampa descer controlada)
  lPacket.Command := 2;
  lPacket.Speed := 150;
  lPacket.time := 60;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);
  //Sleep(60);

  // 6. Para tudo no final
  parar;
end;

procedure TForm1.ExecutarWheeliePendulo;
var
  lPacket: TRobotCommand;
  lData: TIdBytes;
begin
  parar;
  Sleep(50);

  // Balanço 1 para trás
  lPacket.Command := 2;
  lPacket.Speed := 255;
  lPacket.time := 120;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;

  // Balanço 2 para trás (ganhando mais embalo)
  lPacket.Command := 2;
  lPacket.Speed := 255;
  lPacket.time := 120;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;

  // Bote final para frente com força total
  lPacket.Command := 1;
  lPacket.Speed := 255;
  lPacket.time := 280;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;
  sleep(2000);

  lPacket.Command := 2;
  lPacket.Speed := 150;
  lPacket.time := 800;
  lData := RawToBytes(lPacket, SizeOf(lPacket));
  UDP.SendBuffer(lData);

  parar;

end;

///////////////////////////////////////////////////////

procedure TForm1.SendCommand(pCommand, pSpeed: Byte; pTime: Word);
var
  lData: TIdBytes;
begin
  var Packet: TRobotCommand;
  Packet.Command := pCommand;
  Packet.Speed := pSpeed;
  Packet.Time := pTime;

  lData := RawToBytes(Packet, SizeOf(Packet));

  UDP.SendBuffer(lData);

  //memo1.Lines.Clear;
  memo1.Lines.Add('enviou');
end;

procedure TForm1.ActionTTask(pCommand: Byte);
begin
  TTask.Run(
    procedure
    var
      lspeed: Byte;
      ltime: Integer;
    begin
      TThread.Synchronize(nil,
      procedure
      begin
        lspeed := TRUNC(speed.Value);
        ltime := TRUNC(time.Value);
      end);

      SendCommand(pCommand, lspeed, ltime);
      MEMO1.Lines.Add(pCOmmand.ToString);
      Sleep(200);
    end);
end;

procedure TForm1.speedTracking(Sender: TObject);
begin
  lblSpeed.Text := FloatToStr(speed.Value);
end;

procedure TForm1.cForwardMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FIsMoving := True;
  ActionTTask(1);
end;

procedure TForm1.cBackMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FIsMoving := True;
  ActionTTask(2);
end;

procedure TForm1.cRigthMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FIsMoving := True;
  ActionTTask(3);
end;

procedure TForm1.cLeftMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FIsMoving := True;

  ActionTTask(4);
end;

procedure TForm1.DefaultMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  parar;
end;

procedure TForm1.parar;
begin
  FIsMoving := False;
  SendCommand(0, 255, 0);
  memo1.Lines.Add('parou');
end;

procedure TForm1.btnA1Click(Sender: TObject);
begin
  EnviarEstrategiaCombate;
end;




end.
