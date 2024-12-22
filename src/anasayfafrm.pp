{

  Program Adı: IP Konum
  Program Exe Adı: ipkonum.exe
  Kodlayan: Fatih KILIÇ
  Mail: hs.fatih.kilic@gmail.com

  Tanım: genel (yerel değil) ip adreslerinin kaydının yapıldığı konum verisini haritada görüntüler

Genel Bilgi:

  Programda http://ip-api.com/json/{ip adresi} bağlantısı kullanılmıştır. Programın, sorgulanan
  ip adresinin kayıtlarda olması durumunda döndüreceği değer,

  {"status":"success","country":"Bulgaria","countryCode":"BG","region":"22",
  "regionName":"Sofia-Capital","city":"Sofia","zip":"1000","lat":42.6977,
  "lon":23.3219,"timezone":"Europe/Sofia","isp":"Google LLC","org":"Google LLC",
  "as":"AS15169 Google LLC","query":"142.250.187.100"} biçimindedir

  Program, sadece ilgili bağlantının veritabanında mevcut ip adres sonuçlarını geri döndürür

}
unit anasayfafrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ValEdit, ComCtrls, mvMapViewer, mvGpsObj, mvDrawingEngine, IdHTTP;

type
  TfrmAnaSayfa = class(TForm)
    btnSorgula: TButton;
    cbDetay: TCheckBox;
    edtIPAdres: TEdit;
    IdHTTP: TIdHTTP;
    lblIPAdres: TLabel;
    mvHarita: TMapView;
    pnlUst: TPanel;
    sbDurum: TStatusBar;
    vleDetay: TValueListEditor;
    procedure btnSorgulaClick(Sender: TObject);
    procedure cbDetayChange(Sender: TObject);
    procedure edtIPAdresKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure mvHaritaDrawGpsPoint(Sender: TObject;
      ADrawer: TMvCustomDrawingEngine; APoint: TGpsPoint);
    procedure mvHaritaZoomChange(Sender: TObject);
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

{$R *.lfm}
uses Types, mvTypes, fpjson, jsonparser, LCLType;

procedure TfrmAnaSayfa.FormShow(Sender: TObject);
begin

  mvHarita.Active := True;
  mvHaritaZoomChange(Self);
end;

procedure TfrmAnaSayfa.btnSorgulaClick(Sender: TObject);
var
  JSParser: TJSONParser;
  JSData, JSData2: TJSONData;
  Sehir, Ulke, UlkeKodu, Bolge, BolgeAdi, ZamanDilimi,
  ServisSaglayici, Organizasyon, Durum: TJSONStringType;
  Enlem, Boylam: Extended;
  GPSP: TGPSPoint;
  RP: TRealPoint;
  IpAdresi, s: string;
begin

  IpAdresi := Trim(edtIPAdres.Text);

  try
    s := IdHTTP.Get(Format('http://ip-api.com/json/%s', [IpAdresi]));
  except
    ShowMessage('Hata: ip adres verileri alınamıyor!');
    Exit;
  end;

  try

    JSParser := TJSONParser.Create(s, []);
    JSData := JSParser.Parse;

    JSData2 := JSData.FindPath('status');
    if(Assigned(JSData2)) then
    begin

      Durum := JSData2.AsString;
      if(Durum = 'success') then
      begin

        JSData2 := JSData.FindPath('country');
        if(Assigned(JSData2)) then Ulke := JSData2.AsString;
        JSData2 := JSData.FindPath('countryCode');
        if(Assigned(JSData2)) then UlkeKodu := JSData2.AsString;
        JSData2 := JSData.FindPath('region');
        if(Assigned(JSData2)) then Bolge := JSData2.AsString;
        JSData2 := JSData.FindPath('regionName');
        if(Assigned(JSData2)) then BolgeAdi := JSData2.AsString;
        JSData2 := JSData.FindPath('city');
        if(Assigned(JSData2)) then Sehir := JSData2.AsString;
        JSData2 := JSData.FindPath('lat');
        if(Assigned(JSData2)) then Enlem := JSData2.AsFloat;
        JSData2 := JSData.FindPath('lon');
        if(Assigned(JSData2)) then Boylam := JSData2.AsFloat;
        JSData2 := JSData.FindPath('timezone');
        if(Assigned(JSData2)) then ZamanDilimi := JSData2.AsString;
        JSData2 := JSData.FindPath('isp');
        if(Assigned(JSData2)) then ServisSaglayici := JSData2.AsString;
        JSData2 := JSData.FindPath('org');
        if(Assigned(JSData2)) then Organizasyon := JSData2.AsString;

        // ip adres verilerini görüntüle
        vleDetay.Cells[1, 1] := Ulke;
        vleDetay.Cells[1, 2] := UlkeKodu;
        vleDetay.Cells[1, 3] := Bolge;
        vleDetay.Cells[1, 4] := BolgeAdi;
        vleDetay.Cells[1, 5] := Sehir;
        vleDetay.Cells[1, 6] := FloatToStr(Enlem);
        vleDetay.Cells[1, 7] := FloatToStr(Boylam);
        vleDetay.Cells[1, 8] := ZamanDilimi;
        vleDetay.Cells[1, 9] := ServisSaglayici;
        vleDetay.Cells[1, 10] := Organizasyon;

        // ip adres kaydının harita bilgisini harita üzerinde görüntüle
        RP.Lat := Enlem;
        RP.Lon := Boylam;
        mvHarita.Center := RP;
        mvHarita.Invalidate;

        // enlem ve boylam bilgisini harita üzerinde işaretle
        mvHarita.GpsItems.BeginUpdate;
        mvHarita.GpsItems.Clear(0);
        RP.Lat := Enlem;
        RP.Lon := Boylam;

        GPSP := TGpsPoint.CreateFrom(RP);
        GPSP.Name := Sehir;
        mvHarita.GpsItems.Add(GPSP, 0);
        mvHarita.GpsItems.EndUpdate;

        mvHarita.Zoom := 12;
        mvHarita.Invalidate;
      end
      else
      begin

        ShowMessage('Hata: ip adresine ait veriler alınamıyor!');
      end;
    end;

  except
    ShowMessage('Hata: json verileri çözümlenemiyor!');
    Exit;
  end;
end;

procedure TfrmAnaSayfa.cbDetayChange(Sender: TObject);
begin

  vleDetay.Visible := cbDetay.Checked;
end;

procedure TfrmAnaSayfa.edtIPAdresKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin

  if(Key = VK_RETURN) then btnSorgulaClick(Self);
end;

procedure TfrmAnaSayfa.mvHaritaDrawGpsPoint(Sender: TObject;
  ADrawer: TMvCustomDrawingEngine; APoint: TGpsPoint);
var
  pt: TPoint;
  Ex: TSize;
begin

  pt := TMapView(Sender).LatLonToScreen(APoint.RealPoint);

  ADrawer.PenColor := clBlue;
  ADrawer.PenWidth := 2;
  ADrawer.Line(pt.X - 5, pt.Y, pt.X + 5, pt.Y);
  ADrawer.Line(pt.X, pt.Y - 5, pt.X , pt.Y + 5);

  Ex := ADrawer.TextExtent(APoint.Name);

  ADrawer.BrushStyle := bsClear;
  ADrawer.FontColor := clBlue;
  ADrawer.FontName := mvHarita.Font.Name;
  ADrawer.FontSize := mvHarita.Font.Size;
  ADrawer.FontStyle := mvHarita.Font.Style;

  ADrawer.TextOut(pt.X - Ex.CX div 2, pt.Y + 10, APoint.Name);
end;

procedure TfrmAnaSayfa.mvHaritaZoomChange(Sender: TObject);
begin

  sbDurum.SimpleText := 'Büyütme Oranı: ' + mvHarita.Zoom.ToString;
end;

end.
