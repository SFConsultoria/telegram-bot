unit main;

{$mode objfpc}{$H+}

interface

uses
  telegram_integration, config_lib, Classes, SysUtils, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, Buttons, Spin, string_helpers;

const
  TELEGRAM_TOKEN = 'telegram/default/token';

type

  { TfMain }

  TfMain = class(TForm)
    ApplicationProperties1: TApplicationProperties;
    barBottom: TStatusBar;
    btnSendMessage: TBitBtn;
    btnStart: TButton;
    edtMessage: TEdit;
    edtTelegramID: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    mem: TMemo;
    memResult: TMemo;
    mainPageControl: TPageControl;
    pnlBottom: TPanel;
    pnlTop: TPanel;
    edtInterval: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    tmrPoll: TTimer;
    TrayIcon1: TTrayIcon;
    procedure btnSendMessageClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure edtTelegramIDEnter(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure tmrPollTimer(Sender: TObject);
  private
    Config: TMyConfig;
    Telegram: TTelegramIntegration;
    inProcess: boolean;

    procedure onMessageHandler(AMessage: string; var AReply: string;
      var AHandled: boolean);
  public

  end;

var
  fMain: TfMain;

implementation

{$R *.lfm}

{ TfMain }

procedure Delay(AMiliSeconds: DWORD);
var
  DW: DWORD;
begin
  DW := GetTickCount;
  while (GetTickCount < DW + AMiliSeconds) and (not Application.Terminated) do
    Application.ProcessMessages;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  Config := TMyConfig.Create(nil);
  Config.ValidateFile('config.json');

  // Prepare Telegram Bot
  Telegram := TTelegramIntegration.Create;
  Telegram.Token := Config[TELEGRAM_TOKEN];
  Telegram.OnMessage := @onMessageHandler;

  inProcess := False;
  mem.Align := alClient;
  memResult.Align := alClient;
  mainPageControl.ActivePage := TabSheet1;
end;

procedure TfMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Telegram.Free;
  Config.Free;
end;

procedure TfMain.btnStartClick(Sender: TObject);
begin
  tmrPoll.Interval := edtInterval.Value;
  tmrPoll.Enabled := not tmrPoll.Enabled;
  edtInterval.Enabled := not tmrPoll.Enabled;
  if tmrPoll.Enabled then
  begin
    mainPageControl.ActivePage := TabSheet1;
    mem.Lines.Add('== Polling starts every ' + IntToStr(edtInterval.Value) + ' miliseconds.');
    btnStart.Caption := '&Stop';
    btnStart.Color := clRed;
    barBottom.Panels[2].Text:= 'Service running ...';
  end
  else
  begin
    btnStart.Caption := '&Start';
    btnStart.Color := clGreen;
    barBottom.Panels[2].Text:= '';
  end;
end;

procedure TfMain.edtTelegramIDEnter(Sender: TObject);
begin
  if mem.SelText.IsNumeric then
    edtTelegramID.Text := mem.SelText;
end;

procedure TfMain.btnSendMessageClick(Sender: TObject);
begin
  if edtTelegramID.Text = '' then
  begin
    edtTelegramID.SetFocus;
    Exit;
  end;
  if edtMessage.Text = '' then
  begin
    edtMessage.SetFocus;
    Exit;
  end;
  Telegram.SendMessage(edtTelegramID.Text, edtMessage.Text); //without thread
  memResult.Lines.Add(Telegram.ResultText);
end;

procedure TfMain.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if key = 27 then
  begin
    key := 0;
    Close;
  end;
end;

procedure TfMain.FormShow(Sender: TObject);
begin

end;

procedure TfMain.tmrPollTimer(Sender: TObject);
begin
  Telegram.getUpdatesDynamic();
end;

procedure TfMain.onMessageHandler(AMessage: string; var AReply: string;
  var AHandled: boolean);
var
  s: string;
begin
  memResult.Lines.Add(Telegram.RequestContent);
  s := FormatDateTime('yyyy/mm/dd HH:nn:ss', Now) + ' | '
    //+ Telegram.UserID + ':'
    + Telegram.FullName + ' » ' + AMessage;
  mem.Lines.Add(s);

  // Process Your Message here

  AReply := 'echo: ' + AMessage;
  AHandled := True; // set true to send reply to sender
end;

//Delay(250);
//Telegram.SendMessageAsThread(Telegram.ChatID, 'recho: ' + AMessage);


end.


