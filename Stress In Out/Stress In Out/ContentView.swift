import SwiftUI

// Ana Görünüm
struct ContentView: View {
    @State private var karelerKarisik = false
    @State private var soruIsaretiModu = false
    @State private var secilenOyunData: OyunVerisi? = nil
    @State private var toplamSkor = 0
    @State private var stressInModu = true // true = In (Kırmızı/Zor), false = Out (Yeşil/Kolay)
    
    let oyunlar = [
        ("🏃", "Koşu"),
        ("🚿", "Musluk"),
        ("🧩", "Puzzle"),
        ("👟", "Ayakkabı"),
        ("🔌", "Şarj Kablosu"),
        ("🚪", "Dolap Kapağı"),
        ("👕", "Kıyafet"),
        ("🛋️", "Koltuk"),
        ("🫙", "Kavanoz"),
        ("🧦", "Çorap"),
        ("🛗", "Asansör"),
        ("📱", "Telefon"),
        ("💾", "USB"),
        ("🧼", "Sabun"),
        ("🥤", "Bardak"),
        ("📷", "Fotoğraf Makinası")
    ]
    
    @State private var karePozisyonlari: [Int] = Array(0..<16)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Başlık
                Text("STRESS IN OUT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                // Üst Butonlar
                HStack(spacing: 20) {
                    // Zar Butonu - Karıştır ve Soru İşareti Göster
                    Button(action: {
                        withAnimation(.spring()) {
                            karePozisyonlari.shuffle()
                            soruIsaretiModu = true
                            karelerKarisik.toggle()
                        }
                        
                        // 3 saniye sonra soru işaretlerini kaldır
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeInOut) {
                                soruIsaretiModu = false
                            }
                        }
                    }) {
                        Image(systemName: "dice")
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(color: Color.blue.opacity(0.3), radius: 5)
                    }
                    
                    Spacer()
                    
                    // In/Out Toggle Butonu
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            stressInModu.toggle()
                        }
                    }) {
                        Image(systemName: stressInModu ? "flame.fill" : "leaf.fill")
                            .font(.title)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .background(stressInModu ? Color.red : Color.green)
                            .cornerRadius(10)
                            .shadow(color: stressInModu ? Color.red.opacity(0.3) : Color.green.opacity(0.3), radius: 5)
                    }
                }
                .padding(.horizontal)
                
                // 4x4 Oyun Kareleri
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 4), spacing: 15) {
                    ForEach(0..<16) { index in
                        let oyunIndex = karePozisyonlari[index]
                        let oyun = oyunlar[oyunIndex]
                        
                        Button(action: {
                            secilenOyunData = OyunVerisi(index: oyunIndex, stressModu: stressInModu)
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(LinearGradient(
                                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(height: 80)
                                    .shadow(radius: 5)
                                
                                if soruIsaretiModu {
                                    Text("?")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                } else {
                                    Text(oyun.0)
                                        .font(.system(size: 40))
                                }
                            }
                            .rotation3DEffect(
                                .degrees(karelerKarisik ? 360 : 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .fullScreenCover(item: $secilenOyunData) { oyunData in
                OyunDongusuView(
                    baslangicOyunIndex: oyunData.index,
                    oyunlar: oyunlar,
                    toplamSkor: $toplamSkor,
                    stressInModu: oyunData.stressModu,
                    kapatmaCallback: {
                        secilenOyunData = nil
                    }
                )
            }
        }
    }
}

// Oyun Döngüsü View
struct OyunDongusuView: View {
    let baslangicOyunIndex: Int
    let oyunlar: [(String, String)]
    @Binding var toplamSkor: Int
    let stressInModu: Bool
    let kapatmaCallback: () -> Void
    
    @State private var mevcutOyunIndex: Int
    @State private var oyunSayisi = 0
    
    init(baslangicOyunIndex: Int, oyunlar: [(String, String)], toplamSkor: Binding<Int>, stressInModu: Bool, kapatmaCallback: @escaping () -> Void) {
        self.baslangicOyunIndex = baslangicOyunIndex
        self.oyunlar = oyunlar
        self._toplamSkor = toplamSkor
        self.stressInModu = stressInModu
        self.kapatmaCallback = kapatmaCallback
        self._mevcutOyunIndex = State(initialValue: baslangicOyunIndex)
    }
    
    var body: some View {
        ZStack {
            // Mevcut oyunu göster
            switch mevcutOyunIndex {
            case 0:
                // Koşu oyunu yakında eklenecek
                ZStack {
                    VStack {
                        Text("🏃")
                            .font(.system(size: 100))
                        
                        Text("Yakında!")
                            .font(.largeTitle)
                            .padding()
                        
                        Button {
                            oyunSayisi += 1
                            toplamSkor += Int.random(in: 50...200)
                            sonrakiOyun()
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Geri butonu
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                kapatmaCallback()
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
            case 1:
                MuslukOyunuView(
                    stressInModu: stressInModu,
                    toplamSkor: $toplamSkor,
                    oyunBittiCallback: { skor in
                        oyunSayisi += 1
                        sonrakiOyun()
                    }
                )
            case 2:
                PuzzleOyunuView(
                    stressInModu: stressInModu,
                    toplamSkor: $toplamSkor,
                    oyunBittiCallback: { skor in
                        oyunSayisi += 1
                        sonrakiOyun()
                    }
                )
            default:
                ZStack {
                    VStack {
                        Text("🚧")
                            .font(.system(size: 80))
                        
                        Text("\(oyunlar[mevcutOyunIndex].0)")
                            .font(.system(size: 60))
                            .padding()
                        
                        Button {
                            oyunSayisi += 1
                            toplamSkor += Int.random(in: 50...200) // Geçici skor
                            sonrakiOyun()
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Ana menü butonu
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                kapatmaCallback()
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
            
            // Çıkış butonu
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        kapatmaCallback()
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
    
    func sonrakiOyun() {
        mevcutOyunIndex = (mevcutOyunIndex + 1) % oyunlar.count
    }
}

// Veri Modelleri
struct Oyuncu: Identifiable {
    let id = UUID()
    let ad: String
    let skor: Int
}

// Tuple'ı Identifiable yapmak için
struct OyunVerisi: Identifiable {
    let id = UUID()
    let index: Int
    let stressModu: Bool
}
