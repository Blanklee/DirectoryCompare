program Dc;

uses
  Forms,
  MainForm1 in 'MainForm1.pas' {MainForm},
  OptionForm1 in 'OptionForm1.pas' {OptionForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := '���丮 �񱳱�';
  Application.HelpFile := 'Dc.hlp';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TOptionForm, OptionForm);
  Application.Run;
end.
