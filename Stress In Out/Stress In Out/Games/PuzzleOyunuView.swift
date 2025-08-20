import SwiftUI

struct PuzzleOyunuView: View {
    let stressInModu: Bool
    @Binding var toplamSkor: Int
    let oyunBittiCallback: (Int) -> Void
    
    @State private var skor = 0
    @State private var kalanSure = 60
    @State private var oyunBitti = false
    @State private var puzzleParcalari: [PuzzleParca] = []
    @State private var tamamlandi = false
    @State private var ekranGenisligi: CGFloat = 0
    @State private var ekranYuksekligi: CGFloat = 0
    @State private var animasyonGoster = false
    @State private var suruklenenParca: UUID? = nil
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Puzzle boyutları
    let satirSayisi = 3
    let sutunSayisi = 4
    let parcaBoyutu: CGFloat = 80
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arkaplan
                LinearGradient(
                    colors: [Color.purple.opacity(0.2), Color.indigo.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if !oyunBitti {
                    // Puzzle parçaları
                    ForEach(puzzleParcalari) { parca in
                        PuzzleParcaView(
                            parca: parca,
                            parcaBoyutu: parcaBoyutu,
                            surukleniyor: suruklenenParca == parca.id,
                            kenarTipleri: kenarTipleriniHesapla(index: parca.index),
                            toplamGenislik: CGFloat(sutunSayisi) * parcaBoyutu,
                            toplamYukseklik: CGFloat(satirSayisi) * parcaBoyutu,
                            onSurukleBasla: {
                                suruklenenParca = parca.id
                            },
                            onSurukleBitir: {
                                suruklenenParca = nil
                            },
                            onKonumDegisti: { yeniKonum in
                                if let index = puzzleParcalari.firstIndex(where: { $0.id == parca.id }) {
                                    puzzleParcalari[index].mevcutKonum = yeniKonum
                                    komsuKontrol(parcaIndex: index)
                                }
                            }
                        )
                        .zIndex(suruklenenParca == parca.id ? 1000 : Double(100 - parca.index))
                    }
                    
                    // Tamamlandı animasyonu
                    if tamamlandi && animasyonGoster {
                        VStack(spacing: 20) {
                            Text("🎉")
                                .font(.system(size: 100))
                            
                            Text("Tebrikler!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .scaleEffect(animasyonGoster ? 1.2 : 0.8)
                        .opacity(animasyonGoster ? 1 : 0)
                        .position(x: ekranGenisligi / 2, y: ekranYuksekligi / 2)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Geri butonu (sağ üst)
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                toplamSkor += skor
                                oyunBittiCallback(skor)
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .padding(12)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                        
                        Spacer()
                    }
                }
            }
            .onAppear {
                ekranGenisligi = geometry.size.width
                ekranYuksekligi = geometry.size.height
                puzzleOlustur()
            }
            .onReceive(timer) { _ in
                if !oyunBitti {
                    kalanSure -= 1
                    if kalanSure <= 0 {
                        oyunBitti = true
                        toplamSkor += skor
                        oyunBittiCallback(skor)
                    }
                }
            }
        }
    }
    
    func puzzleOlustur() {
        puzzleParcalari = []
        
        // IN modunda 11 parça, OUT modunda 12 parça
        let parcaSayisi = stressInModu ? 11 : 12
        
        // Ekranın tam ortası
        let ortaX = ekranGenisligi / 2
        let ortaY = ekranYuksekligi / 2
        
        for i in 0..<parcaSayisi {
            let parca = PuzzleParca(
                index: i,
                mevcutKonum: CGPoint(x: ortaX, y: ortaY),
                gercekKonum: hesaplaGercekKonum(index: i)
            )
            
            puzzleParcalari.append(parca)
        }
    }
    
    func hesaplaGercekKonum(index: Int) -> CGPoint {
        let satir = index / sutunSayisi
        let sutun = index % sutunSayisi
        
        let x = CGFloat(sutun) * parcaBoyutu + parcaBoyutu/2
        let y = CGFloat(satir) * parcaBoyutu + parcaBoyutu/2
        
        return CGPoint(
            x: ekranGenisligi / 2 - (CGFloat(sutunSayisi) * parcaBoyutu / 2) + x,
            y: ekranYuksekligi / 2 - (CGFloat(satirSayisi) * parcaBoyutu / 2) + y
        )
    }
    
    func kenarTipleriniHesapla(index: Int) -> KenarTipleri {
        let satir = index / sutunSayisi
        let sutun = index % sutunSayisi
        
        var ustKenar: KenarTipi = KenarTipi.duz
        var sagKenar: KenarTipi = KenarTipi.duz
        var altKenar: KenarTipi = KenarTipi.duz
        var solKenar: KenarTipi = KenarTipi.duz
        
        // Üst kenar (ilk satır hariç)
        if satir > 0 {
            ustKenar = (index % 2 == 0) ? KenarTipi.cikinti : KenarTipi.girinti
        }
        
        // Sağ kenar (son sütun hariç)
        if sutun < sutunSayisi - 1 {
            sagKenar = ((satir + sutun) % 2 == 0) ? KenarTipi.cikinti : KenarTipi.girinti
        }
        
        // Alt kenar (son satır hariç)
        if satir < satirSayisi - 1 {
            altKenar = (index % 2 == 0) ? KenarTipi.girinti : KenarTipi.cikinti
        }
        
        // Sol kenar (ilk sütun hariç)
        if sutun > 0 {
            let solKomsuIndex = satir * sutunSayisi + (sutun - 1)
            let komsuSagKenar = ((satir + sutun - 1) % 2 == 0) ? KenarTipi.cikinti : KenarTipi.girinti
            solKenar = (komsuSagKenar == KenarTipi.cikinti) ? KenarTipi.girinti : KenarTipi.cikinti
        }
        
        return KenarTipleri(ust: ustKenar, sag: sagKenar, alt: altKenar, sol: solKenar)
    }
    
    func komsuKontrol(parcaIndex: Int) {
        let parca = puzzleParcalari[parcaIndex]
        let tolerans: CGFloat = 30
        
        // Her parçayı kontrol et
        for i in 0..<puzzleParcalari.count {
            if i == parcaIndex { continue }
            
            let digerParca = puzzleParcalari[i]
            let beklenenfarkX = parca.gercekKonum.x - digerParca.gercekKonum.x
            let beklenenfarkY = parca.gercekKonum.y - digerParca.gercekKonum.y
            
            let gercekFarkX = parca.mevcutKonum.x - digerParca.mevcutKonum.x
            let gercekFarkY = parca.mevcutKonum.y - digerParca.mevcutKonum.y
            
            // Doğru pozisyonda mı?
            if abs(gercekFarkX - beklenenfarkX) < tolerans &&
               abs(gercekFarkY - beklenenfarkY) < tolerans {
                
                // Doğru pozisyona yerleştir
                withAnimation(.spring()) {
                    puzzleParcalari[parcaIndex].mevcutKonum = CGPoint(
                        x: digerParca.mevcutKonum.x + beklenenfarkX,
                        y: digerParca.mevcutKonum.y + beklenenfarkY
                    )
                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
                
                // Skor ekle
                skor += 5
                
                // Tamamlandı mı kontrol et
                tamamlandiKontrol()
                break
            }
        }
    }
    
    func tamamlandiKontrol() {
        // Tüm parçalar doğru yerleşti mi?
        var dogruYerlesmisler = true
        
        // En az bir parça referans olarak alınır
        guard let ilkParca = puzzleParcalari.first else { return }
        
        for i in 1..<puzzleParcalari.count {
            let parca = puzzleParcalari[i]
            let beklenenfarkX = parca.gercekKonum.x - ilkParca.gercekKonum.x
            let beklenenfarkY = parca.gercekKonum.y - ilkParca.gercekKonum.y
            
            let gercekFarkX = parca.mevcutKonum.x - ilkParca.mevcutKonum.x
            let gercekFarkY = parca.mevcutKonum.y - ilkParca.mevcutKonum.y
            
            if abs(gercekFarkX - beklenenfarkX) > 5 ||
               abs(gercekFarkY - beklenenfarkY) > 5 {
                dogruYerlesmisler = false
                break
            }
        }
        
        if dogruYerlesmisler && puzzleParcalari.count == 12 {
            tamamlandi = true
            skor += 50 // Bonus puan
            
            withAnimation(.spring()) {
                animasyonGoster = true
            }
            
            // 2 saniye sonra sonraki oyuna geç
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                toplamSkor += skor
                oyunBittiCallback(skor)
            }
        }
    }
}

// Puzzle Parça View
struct PuzzleParcaView: View {
    let parca: PuzzleParca
    let parcaBoyutu: CGFloat
    let surukleniyor: Bool
    let kenarTipleri: KenarTipleri
    let toplamGenislik: CGFloat
    let toplamYukseklik: CGFloat
    let onSurukleBasla: () -> Void
    let onSurukleBitir: () -> Void
    let onKonumDegisti: (CGPoint) -> Void
    
    @State private var mevcutKonum: CGPoint
    
    init(parca: PuzzleParca, parcaBoyutu: CGFloat, surukleniyor: Bool,
         kenarTipleri: KenarTipleri, toplamGenislik: CGFloat, toplamYukseklik: CGFloat,
         onSurukleBasla: @escaping () -> Void, onSurukleBitir: @escaping () -> Void,
         onKonumDegisti: @escaping (CGPoint) -> Void) {
        self.parca = parca
        self.parcaBoyutu = parcaBoyutu
        self.surukleniyor = surukleniyor
        self.kenarTipleri = kenarTipleri
        self.toplamGenislik = toplamGenislik
        self.toplamYukseklik = toplamYukseklik
        self.onSurukleBasla = onSurukleBasla
        self.onSurukleBitir = onSurukleBitir
        self.onKonumDegisti = onKonumDegisti
        self._mevcutKonum = State(initialValue: parca.mevcutKonum)
    }
    
    var body: some View {
        ZStack {
            // Resim parçası
            Image("stressinout")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: toplamGenislik + parcaBoyutu, height: toplamYukseklik + parcaBoyutu)
                .offset(
                    x: -CGFloat(parca.index % 4) * parcaBoyutu - parcaBoyutu/2,
                    y: -CGFloat(parca.index / 4) * parcaBoyutu - parcaBoyutu/2
                )
                .mask(
                    PuzzleShape(kenarTipleri: kenarTipleri)
                        .frame(width: parcaBoyutu, height: parcaBoyutu)
                )
                .frame(width: parcaBoyutu, height: parcaBoyutu)
                .background(
                    PuzzleShape(kenarTipleri: kenarTipleri)
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                    PuzzleShape(kenarTipleri: kenarTipleri)
                        .stroke(Color.black.opacity(0.5), lineWidth: 1)
                )
        }
        .frame(width: parcaBoyutu, height: parcaBoyutu)
        .shadow(color: surukleniyor ? .black.opacity(0.5) : .black.opacity(0.2), radius: surukleniyor ? 10 : 3)
        .scaleEffect(surukleniyor ? 1.05 : 1.0)
        .position(mevcutKonum)
        .gesture(
            DragGesture()
                .onChanged { value in
                    onSurukleBasla()
                    mevcutKonum = value.location
                    onKonumDegisti(value.location)
                }
                .onEnded { _ in
                    onSurukleBitir()
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mevcutKonum)
        .onChange(of: parca.mevcutKonum) { yeniKonum in
            mevcutKonum = yeniKonum
        }
    }
}

// Kenar Tipleri
enum KenarTipi {
    case duz
    case girinti
    case cikinti
}

struct KenarTipleri {
    let ust: KenarTipi
    let sag: KenarTipi
    let alt: KenarTipi
    let sol: KenarTipi
}

// Puzzle Şekli
struct PuzzleShape: Shape {
    let kenarTipleri: KenarTipleri
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let kenarBoyutu = rect.width
        let girintiDerinlik = kenarBoyutu * 0.25
        let girintiGenislik = kenarBoyutu * 0.3
        
        // Sol üst köşeden başla
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Üst kenar
        switch kenarTipleri.ust {
        case .duz:
            path.addLine(to: CGPoint(x: kenarBoyutu, y: 0))
        case .girinti:
            let baslangic = (kenarBoyutu - girintiGenislik) / 2
            let bitis = baslangic + girintiGenislik
            
            path.addLine(to: CGPoint(x: baslangic, y: 0))
            path.addCurve(
                to: CGPoint(x: bitis, y: 0),
                control1: CGPoint(x: baslangic, y: girintiDerinlik),
                control2: CGPoint(x: bitis, y: girintiDerinlik)
            )
            path.addLine(to: CGPoint(x: kenarBoyutu, y: 0))
        case .cikinti:
            let baslangic = (kenarBoyutu - girintiGenislik) / 2
            let bitis = baslangic + girintiGenislik
            
            path.addLine(to: CGPoint(x: baslangic, y: 0))
            path.addCurve(
                to: CGPoint(x: bitis, y: 0),
                control1: CGPoint(x: baslangic, y: -girintiDerinlik),
                control2: CGPoint(x: bitis, y: -girintiDerinlik)
            )
            path.addLine(to: CGPoint(x: kenarBoyutu, y: 0))
        }
        
        // Sağ kenar
        switch kenarTipleri.sag {
        case .duz:
            path.addLine(to: CGPoint(x: kenarBoyutu, y: kenarBoyutu))
        case .girinti:
            let baslangic = (kenarBoyutu - girintiGenislik) / 2
            let bitis = baslangic + girintiGenislik
            
            path.addLine(to: CGPoint(x: kenarBoyutu, y: baslangic))
            path.addCurve(
                to: CGPoint(x: kenarBoyutu, y: bitis),
                control1: CGPoint(x: kenarBoyutu - girintiDerinlik, y: baslangic),
                control2: CGPoint(x: kenarBoyutu - girintiDerinlik, y: bitis)
            )
            path.addLine(to: CGPoint(x: kenarBoyutu, y: kenarBoyutu))
        case .cikinti:
            let baslangic = (kenarBoyutu - girintiGenislik) / 2
            let bitis = baslangic + girintiGenislik
            
            path.addLine(to: CGPoint(x: kenarBoyutu, y: baslangic))
            path.addCurve(
                to: CGPoint(x: kenarBoyutu, y: bitis),
                control1: CGPoint(x: kenarBoyutu + girintiDerinlik, y: baslangic),
                control2: CGPoint(x: kenarBoyutu + girintiDerinlik, y: bitis)
            )
            path.addLine(to: CGPoint(x: kenarBoyutu, y: kenarBoyutu))
        }
        
        // Alt kenar
        switch kenarTipleri.alt {
        case .duz:
            path.addLine(to: CGPoint(x: 0, y: kenarBoyutu))
        case .girinti:
            let baslangic = (kenarBoyutu - girintiGenislik) / 2
            let bitis = baslangic + girintiGenislik
            
            path.addLine(to: CGPoint(x: bitis, y: kenarBoyutu))
            path.addCurve(
                to: CGPoint(x: baslangic, y: kenarBoyutu),
                control1: CGPoint(x: bitis, y: kenarBoyutu - girintiDerinlik),
                control2: CGPoint(x: baslangic, y: kenarBoyutu - girintiDerinlik)
            )
            path.addLine(to: CGPoint(x: 0, y: kenarBoyutu))
        case .cikinti:
            let baslangic = (kenarBoyutu - girintiGenislik) / 2
            let bitis = baslangic + girintiGenislik
            
            path.addLine(to: CGPoint(x: bitis, y: kenarBoyutu))
            path.addCurve(
                to: CGPoint(x: baslangic, y: kenarBoyutu),
                control1: CGPoint(x: bitis, y: kenarBoyutu + girintiDerinlik),
                control2: CGPoint(x: baslangic, y: kenarBoyutu + girintiDerinlik)
            )
            path.addLine(to: CGPoint(x: 0, y: kenarBoyutu))
        }
        
        // Sol kenar
        switch kenarTipleri.sol {
        case .duz:
            path.addLine(to: CGPoint(x: 0, y: 0))
        case .girinti:
            let baslangic = (kenarBoyutu - girintiGenislik) / 2
            let bitis = baslangic + girintiGenislik
            
            path.addLine(to: CGPoint(x: 0, y: bitis))
            path.addCurve(
                to: CGPoint(x: 0, y: baslangic),
                control1: CGPoint(x: girintiDerinlik, y: bitis),
                control2: CGPoint(x: girintiDerinlik, y: baslangic)
            )
            path.addLine(to: CGPoint(x: 0, y: 0))
        case .cikinti:
            let baslangic = (kenarBoyutu - girintiGenislik) / 2
            let bitis = baslangic + girintiGenislik
            
            path.addLine(to: CGPoint(x: 0, y: bitis))
            path.addCurve(
                to: CGPoint(x: 0, y: baslangic),
                control1: CGPoint(x: -girintiDerinlik, y: bitis),
                control2: CGPoint(x: -girintiDerinlik, y: baslangic)
            )
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        path.closeSubpath()
        return path
    }
}

// Puzzle Parça Modeli
struct PuzzleParca: Identifiable {
    let id = UUID()
    let index: Int
    var mevcutKonum: CGPoint
    let gercekKonum: CGPoint
}
