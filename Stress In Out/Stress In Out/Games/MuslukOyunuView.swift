import SwiftUI

struct MuslukOyunuView: View {
    let stressInModu: Bool
    @Binding var toplamSkor: Int
    let oyunBittiCallback: (Int) -> Void
    
    @State private var suDamlalari: [SuDamlasi] = []
    @State private var skor = 0
    @State private var kalanSure = 30
    @State private var oyunBitti = false
    @State private var kasikPozisyon: CGPoint = .zero
    @State private var kasikTemiz = false
    @State private var kasikMuslukAltinda = false
    @State private var suSicramasi: [SuSicrama] = []
    @State private var ekranGenisligi: CGFloat = 0
    @State private var ekranYuksekligi: CGFloat = 0
    @State private var temizKasiklar: [TemizKasik] = []
    @State private var kasikSurukleniyorMu = false
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    let sureTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arkaplan
                LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if !oyunBitti {
                    VStack {
                        // Musluk
                        ZStack {
                            // Musluk gövdesi
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray, Color.gray.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 100, height: 120)
                            
                            // Musluk başı
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.gray.opacity(0.9), Color.gray],
                                        center: .topLeading,
                                        startRadius: 5,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .offset(y: -20)
                            
                            // Musluk ağzı
                            Capsule()
                                .fill(Color.gray.opacity(0.8))
                                .frame(width: 40, height: 60)
                                .offset(y: 60)
                        }
                        .padding(.top, 30)
                        
                        Spacer()
                    }
                    
                    // Su damlaları
                    ForEach(suDamlalari) { damlasi in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)],
                                    center: .topLeading,
                                    startRadius: 1,
                                    endRadius: 10
                                )
                            )
                            .frame(width: 15, height: 15)
                            .position(x: damlasi.x, y: damlasi.y)
                    }
                    
                    // Su sıçramaları (IN modunda)
                    if stressInModu {
                        ForEach(suSicramasi) { sicrama in
                            Circle()
                                .fill(Color.blue.opacity(sicrama.opacity))
                                .frame(width: sicrama.boyut, height: sicrama.boyut)
                                .position(x: sicrama.x, y: sicrama.y)
                        }
                    }
                    
                    // Kirli Kaşık
                    if !kasikTemiz {
                        ZStack {
                            // Kaşık gövdesi
                            Ellipse()
                                .fill(Color.gray)
                                .frame(width: 60, height: 100)
                            
                            // Kaşık sapı
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 15, height: 80)
                                .offset(y: 70)
                            
                            // Kir lekeleri
                            ForEach(0..<5) { i in
                                Circle()
                                    .fill(Color.brown.opacity(0.7))
                                    .frame(width: CGFloat.random(in: 10...20))
                                    .offset(
                                        x: CGFloat.random(in: -20...20),
                                        y: CGFloat.random(in: -30...30)
                                    )
                            }
                        }
                        .position(kasikPozisyon)
                        .scaleEffect(kasikSurukleniyorMu ? 1.1 : 1.0)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    kasikSurukleniyorMu = true
                                    kasikPozisyon = value.location
                                    
                                    // Musluk altında mı kontrol et
                                    let muslukX = ekranGenisligi / 2
                                    let muslukY: CGFloat = 210
                                    
                                    if abs(kasikPozisyon.x - muslukX) < 50 &&
                                       abs(kasikPozisyon.y - muslukY) < 50 {
                                        kasikMuslukAltinda = true
                                        
                                        if stressInModu {
                                            // Su sıçrat
                                            suSicrat()
                                        } else {
                                            // Kaşığı temizle
                                            kasikTemizle()
                                        }
                                    } else {
                                        kasikMuslukAltinda = false
                                    }
                                }
                                .onEnded { _ in
                                    kasikSurukleniyorMu = false
                                }
                        )
                    }
                    
                    // Temiz kaşıklar (sağ tarafta)
                    ForEach(temizKasiklar) { kasik in
                        ZStack {
                            // Kaşık gövdesi
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.9), Color.gray.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 70)
                            
                            // Kaşık sapı
                            Rectangle()
                                .fill(Color.gray.opacity(0.8))
                                .frame(width: 10, height: 50)
                                .offset(y: 50)
                            
                            // Parıltı efekti
                            Ellipse()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 20, height: 30)
                                .offset(x: -10, y: -10)
                        }
                        .position(kasik.pozisyon)
                        .rotation3DEffect(
                            .degrees(kasik.rotasyon),
                            axis: (x: 0, y: 1, z: 0)
                        )
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
                kasikPozisyon = CGPoint(x: ekranGenisligi / 2, y: ekranYuksekligi - 200)
            }
            .onReceive(timer) { _ in
                if !oyunBitti {
                    // Su damlaları oluştur
                    if Int.random(in: 0...2) == 0 {
                        let yeniDamla = SuDamlasi(
                            x: ekranGenisligi / 2,
                            y: 210
                        )
                        suDamlalari.append(yeniDamla)
                    }
                    
                    // Damlaları hareket ettir
                    for i in suDamlalari.indices.reversed() {
                        suDamlalari[i].y += 8
                        
                        // Ekrandan çıkan damlaları temizle
                        if suDamlalari[i].y > ekranYuksekligi {
                            suDamlalari.remove(at: i)
                        }
                    }
                    
                    // Su sıçramalarını güncelle
                    for i in suSicramasi.indices.reversed() {
                        suSicramasi[i].y += suSicramasi[i].hiz.dy
                        suSicramasi[i].x += suSicramasi[i].hiz.dx
                        suSicramasi[i].hiz.dy += 0.5 // Yerçekimi
                        suSicramasi[i].opacity -= 0.02
                        suSicramasi[i].boyut += 0.5
                        
                        if suSicramasi[i].opacity <= 0 || suSicramasi[i].y > ekranYuksekligi {
                            suSicramasi.remove(at: i)
                        }
                    }
                }
            }
            .onReceive(sureTimer) { _ in
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
    
    func kasikTemizle() {
        if kasikMuslukAltinda && !kasikTemiz && !stressInModu {
            withAnimation(.easeInOut(duration: 0.5)) {
                kasikTemiz = true
            }
            
            // Temiz kaşığı kenara koy
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let yeniTemizKasik = TemizKasik(
                    pozisyon: CGPoint(
                        x: ekranGenisligi - 80 - CGFloat(temizKasiklar.count % 3) * 50,
                        y: 150 + CGFloat(temizKasiklar.count / 3) * 80
                    ),
                    rotasyon: Double.random(in: -15...15)
                )
                
                withAnimation(.spring()) {
                    temizKasiklar.append(yeniTemizKasik)
                }
                
                skor += 10
                
                // Yeni kirli kaşık getir
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    kasikPozisyon = CGPoint(x: ekranGenisligi / 2, y: ekranYuksekligi - 200)
                    kasikTemiz = false
                    kasikMuslukAltinda = false
                }
            }
        }
    }
    
    func suSicrat() {
        if kasikMuslukAltinda && stressInModu {
            // Su sıçramaları oluştur
            for _ in 0..<10 {
                let sicrama = SuSicrama(
                    x: kasikPozisyon.x + CGFloat.random(in: -30...30),
                    y: kasikPozisyon.y,
                    hiz: CGVector(
                        dx: CGFloat.random(in: -5...5),
                        dy: CGFloat.random(in: -10...(-5))
                    ),
                    boyut: CGFloat.random(in: 5...15),
                    opacity: 1.0
                )
                suSicramasi.append(sicrama)
            }
        }
    }
}

// Veri yapıları
struct SuDamlasi: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
}

struct SuSicrama: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var hiz: CGVector
    var boyut: CGFloat
    var opacity: Double
}

struct TemizKasik: Identifiable {
    let id = UUID()
    let pozisyon: CGPoint
    let rotasyon: Double
}
