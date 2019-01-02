program CS;

uses Windows, Messages;

var
  WindowClass: TWndClassA;
  hFont, hFrm, hLst, hBtnSetar, hBtnLimpar, hBtnAtuali, hGrpJanelas,
  hGrpTitulo, hStcAtual, hStcNovo, hStcSobre, hEdtAtual, hEdtNovo, MyBrush: DWORD;
  Msg: TMsg;

{$R XPManifest\XPManifest.res}
{$R 'ConIcon\ConIcon.res' 'ConIcon\ConIcon.rc'}

function GetText(Wnd: DWORD): string;
 var
  Text: array [0..255] of Char;
begin
  GetWindowTextA(Wnd, Text, 255);
  Result := Text;
end;

procedure XPManifest;
begin
  GetProcAddress(LoadLibrary('comctl32.dll'), 'InitCommonControls');
  asm
    CMP EAX, 0
    JZ @Fail
    CALL EAX
    @Fail:
  end;
end;

procedure SetFormIcons(FormHandle: HWND; const SmallIconName, LargeIconName: string);
 var
  hIconS, hIconL: HICON;
begin
  if (SmallIconName <> '') then
  begin
    hIconS := LoadIcon(hInstance, PChar(SmallIconName));
    if (hIconS > 0) then
    begin
      SendMessage(FormHandle, WM_SETICON, ICON_SMALL, hIconS);
      SetClassLong(FormHandle, GCL_HICONSM, LPARAM(hIconS));
      if (hIconS > 0) then
        DestroyIcon(hIconS);
    end;
  end;
  if (LargeIconName <> '') then
  begin
    hIconL := LoadIcon(hInstance, PChar(LargeIconName));
    if (hIconL > 0) then
    begin
      SendMessage(FormHandle, WM_SETICON, ICON_BIG, hIconL);
      SetClassLong(FormHandle, GCL_HICON, LPARAM(hIconL));
      if (hIconL > 0) then
        DestroyIcon(hIconL);
    end;
  end;
end;

procedure CreateMyClass(out WindowClass: TWndClassA; hInst: DWORD;
WindowProc: Pointer; BackColor: DWORD; ClassName: PAnsiChar);
begin
  with WindowClass do
  begin
    hInstance     := hInst;
    lpfnWndProc   := WindowProc;
    hbrBackground := BackColor;
    lpszClassname := ClassName;
    hCursor       := LoadCursor(0, IDC_ARROW);
    style         := CS_OWNDC or CS_VREDRAW or CS_HREDRAW or CS_DROPSHADOW;
  end;
  RegisterClassA(WindowClass);
end;

function CreateMyFont(FontName: string; Size, Style: Integer;
Italic, Underline, Strikeout: Boolean): DWORD;
begin
  Result := CreateFontA(Size, 0, 0, 0, Style, DWORD(Italic), DWORD(Underline),
  DWORD(Strikeout), DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
  DEFAULT_QUALITY, DEFAULT_PITCH, PChar(FontName));
end;

function CreateMyForm(hInst: DWORD; ClassName, Caption: PAnsiChar;
Width, Heigth, Icon: Integer; Transparence: Byte): DWORD;
begin
  Result := CreateWindowExA(WS_EX_WINDOWEDGE or WS_EX_LAYERED, ClassName, Caption,
  WS_VISIBLE or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX,
  (GetSystemMetrics(SM_CXSCREEN) - Width)  div 2, //Center X
  (GetSystemMetrics(SM_CYSCREEN) - Heigth) div 2, //Center Y
  Width, Heigth, 0, 0, hInst, nil);
  SetLayeredWindowAttributes(Result, 0, Transparence, LWA_ALPHA);
  //SendMessageA(Result, WM_SETICON, 0, Icon);
  SetFormIcons(Result, 'ICO32', 'ICO64');
  UpdateWindow(Result);
end;

function CreateMyComponent(hInst: DWORD; ClassName, Caption: PAnsiChar;
Font, x, y, Width, Heigth, Parent: Integer; StyleEx, Style: DWORD): DWORD;
begin
  Result := CreateWindowExA(StyleEx, ClassName, Caption, WS_CHILD or WS_VISIBLE
  or Style, x, y, Width, Heigth, Parent, 0, hInst, nil);
  if (Font <> 0) then
    SendMessageA(Result, WM_SETFONT, Font, 0);
end;

function EnumWindowsProc(Wnd: HWND): Boolean; stdcall;
 var
  Caption: array [0..128] of Char;
begin
  try
    if IsWindowVisible(Wnd) and ((GetWindowLong(Wnd, GWL_HWNDPARENT) = 0) or
    (HWND(GetWindowLong(Wnd, GWL_HWNDPARENT)) = GetDesktopWindow)) and
    ((GetWindowLong(Wnd, GWL_EXSTYLE) and WS_EX_TOOLWINDOW) = 0) then
    begin
      SendMessageA(Wnd, WM_GETTEXT, Sizeof(Caption), Integer(@Caption));
      SendMessageA(hLst, LB_ADDSTRING, 0, Integer(string(Caption)));
    end;
  except
    Result := False;
    Exit;
  end;
  Result := True;
end;

function WindowProc(hWnd: DWORD; uMsg, wParam, lParam: Integer): Integer; stdcall;
 var
  H: THandle;
  Line: Integer;
  TxtLine: array [0..255] of Char;
begin
  Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  case uMsg of
    WM_COMMAND:
    begin
      if (lParam = hBtnSetar) then
      begin
        if ((GetText(hEdtAtual) <> '') and (GetText(hEdtNovo) <> '')) then
        begin
          H := FindWindowA(nil, PChar(GetText(hEdtAtual)));
          if (H <> 0) then
          begin
            SetWindowTextA(H, PChar(GetText(hEdtNovo)));
            MessageBoxA(hFrm, 'Título da Janela Alterado Com Sucesso',
            'Confirmação', MB_OK + MB_DEFBUTTON1 + MB_ICONINFORMATION);
            SendMessageA(hFrm, WM_COMMAND, 0, hBtnAtuali);
          end else begin
            MessageBoxA(hFrm, 'Erro ao Tentar Alterar o Título da Janela',
            'Erro', MB_OK + MB_DEFBUTTON1 + MB_ICONERROR);
          end;
        end else begin
          MessageBoxA(hFrm, 'Erro, Campo(s) Vazio(s)', 'Erro',
          MB_OK + MB_DEFBUTTON1 + MB_ICONERROR);
        end;
      end;
      if (lParam = hBtnLimpar) then
      begin
        SetWindowTextA(hEdtNovo, '');
        SetWindowTextA(hEdtAtual, '');
        //RedrawWindow(hFrm, nil, 0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
        //UpdateWindow(hEdtNovo);
      end;
      if (lParam = hBtnAtuali) then
      begin
        SendMessageA(hLst, LB_RESETCONTENT, 0, 0);
        EnumWindows(@EnumWindowsProc, 0);
        SetFocus(hLst);
      end;
      if (lParam = hLst) then
      begin
        Line := SendMessageA(hLst, LB_GETCURSEL, 0, 0);
        if (Line <> - 1) then
        begin
          SendMessageA(hLst, LB_GETTEXT, Line, Integer(@TxtLine));
          SendMessageA(hFrm, WM_COMMAND, 0, hBtnLimpar);
          SetWindowTextA(hEdtAtual, PChar(string(TxtLine)));
        end;
      end;
    end;
    WM_CTLCOLORLISTBOX:
    begin
      SetTextColor(wParam, $FFFFFF);
      SetBkColor(wParam, 0); //$453F3F
      Result := MyBrush;
      //SetTextColor(wParam, $FFFFFF);
      //SetBkColor(wParam, TRANSPARENT);  //0
      //Result := GetStockObject(BLACK_BRUSH);
    end;
    WM_CTLCOLORSTATIC:
    begin
      //if (lParam <> hEdtAtual) then // quando o edit é ES_READONLY, ele é pintado aqui
      //begin
        //SetTextColor(wParam, $FFFFFF);
        //SetBkColor(wParam, TRANSPARENT); //SetBkMode(Wparam, TRANSPARENT);
        //Result := GetStockObject(NULL_BRUSH);
      //end else begin
        SetTextColor(wParam, $FFFFFF);
        SetBkColor(wParam, 0);
        Result := MyBrush;
      //end;
    end;
    WM_CTLCOLOREDIT:
    begin
      SetTextColor(wParam, $FFFFFF);
      SetBkColor(wParam, 0); //$453F3F
      Result := MyBrush;
      //SetTextColor(wParam, $FFFFFF);
      //SetBkColor(wParam, TRANSPARENT);  //$453F3F
      //Result := GetStockObject(NULL_BRUSH);
    end;
    WM_DESTROY:
    begin
      PostQuitMessage(0);
      Halt;
    end;
  end;
end;

begin
  XPManifest;
  MyBrush := CreateSolidBrush(100);
  CreateMyClass(WindowClass, HInstance, @WindowProc, CreateSolidBrush(0), 'FrmCSPrincipal'); //$D9E9EC
  hFont := CreateMyFont('Times New Roman', -14, FW_NORMAL, False, False, False);
  hFrm  := CreateMyForm(HInstance, 'FrmCSPrincipal', 'Caption Switcher v1.0', 346, 324, 7, 255);
  hLst  := CreateMyComponent(HInstance, 'ListBox', '', hFont, 25, 32, 290, 52,
  hFrm, WS_EX_CLIENTEDGE, LBS_HASSTRINGS or LBS_NOTIFY or LBS_SORT or WS_VSCROLL);
  hBtnSetar   := CreateMyComponent(HInstance, 'Button', 'Setar', hFont, 25, 232, 75, 25, hFrm, 0, BS_NULL);
  hBtnLimpar  := CreateMyComponent(HInstance, 'Button', 'Limpar', hFont, 107, 232, 75, 25, hFrm, 0, 0);
  hBtnAtuali  := CreateMyComponent(HInstance, 'Button', 'Atualizar', hFont, 25, 100, 75, 25, hFrm, 0, 0);
  hGrpJanelas := CreateMyComponent(HInstance, 'Button', 'Janelas Detectadas:',
  hFont, 8, 8, 325, 135, hFrm, 0, WS_BORDER or BS_GROUPBOX);
  hGrpTitulo  := CreateMyComponent(HInstance, 'Button', 'Título da Janela:',
  hFont, 8, 150, 325, 126, hFrm, 0, WS_BORDER or BS_GROUPBOX);
  hStcAtual   := CreateMyComponent(HInstance, 'Static', 'Atual:', hFont, 25, 176, 45, 20, hFrm, 0, WS_BORDER or SS_NOTIFY);
  hStcNovo    := CreateMyComponent(HInstance, 'Static', 'Novo:', hFont, 25, 196, 38, 20, hFrm, 0, WS_BORDER or SS_NOTIFY);
  hStcSobre   := CreateMyComponent(HInstance, 'Static', 'Criado Por rios0rios0 ...',
  hFont, 8, 276, 200, 20, hFrm, 0, WS_BORDER or SS_NOTIFY);
  hEdtAtual   := CreateMyComponent(HInstance, 'Edit', '', hFont, 75, 174, 240, 23,
  hFrm, WS_EX_CLIENTEDGE, WS_BORDER or ES_CENTER or ES_AUTOHSCROLL or ES_READONLY);
  hEdtNovo    := CreateMyComponent(HInstance, 'Edit', '', hFont, 75, 194, 240, 23,
  hFrm, WS_EX_CLIENTEDGE, WS_BORDER or ES_CENTER or ES_AUTOHSCROLL);

  //ON CREATE
  SendMessageA(hFrm, WM_COMMAND, 0, hBtnAtuali);
  while (GetMessageA(Msg, 0, 0, 0)) do
  begin
    TranslateMessage(Msg);
    DispatchMessageA(Msg);
  end;
end.
