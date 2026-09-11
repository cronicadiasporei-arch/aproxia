# Aproxia — Plan de realizat

**Data planului:** 11 septembrie 2026  
**Produs:** Aproxia Remote Access & Support  
**Stadiu:** Preview / dezvoltare activă

Acest document este punctul de referință pentru dezvoltarea Aproxia. Se actualizează pe măsură ce implementăm etapele de mai jos.

## 1. Finalizarea aplicației Aproxia

Prioritate imediată:

- Stabilizarea aplicației Windows x64 și a variantei single-file `Aproxia-Portable-x64.exe`.
- Interfața principală trebuie adusă cât mai aproape de designul Aproxia aprobat: sidebar premium bleumarin, logo Aproxia, carduri albe, accente albastre și stare de conectare clară.
- Corectarea ID-ului local astfel încât să fie generat, actualizat și afișat complet.
- Verificarea funcțională a butoanelor: conectare remote, transfer fișiere, terminal, copiere ID/parolă, regenerare parolă, setări și instalare.
- Eliminarea brandingului RustDesk din toate elementele vizibile utilizatorului: titluri, tooltip-uri, taskbar, iconițe, installer, texte și ferestre auxiliare.
- Refacerea completă a paginii **Setări / Despre Aproxia**: toate meniurile în română, `Info su RustDesk` devine `Despre Aproxia`, identitatea vizuală Aproxia, versiunea Aproxia, build-ul Aproxia și linkurile Aproxia. Nu trebuie să rămână linkuri comerciale RustDesk/Purslane în interfața de produs.
- Informațiile și atribuirile open-source obligatorii vor fi mutate/prezentate corect într-o zonă separată `Licențe open-source`, fără a pretinde că Aproxia este autorul codului terț.
- Păstrarea licențelor și atribuirilor open-source obligatorii; referințele tehnice interne care sunt necesare upstream-ului nu trebuie eliminate dacă afectează mentenanța sau compatibilitatea.
- Româna va fi limba implicită a produsului.
- Înlocuirea iconițelor Windows/portable cu identitatea Aproxia finală.
- Testarea unei sesiuni remote reale înainte de trecerea la etapa comercială.

## 2. Infrastructură self-hosted Aproxia

După stabilizarea clientului:

- Server propriu Aproxia pentru ID/rendezvous și relay.
- VPS Linux, preferabil Ubuntu 24.04 LTS, cu IPv4 public și trafic suficient.
- Configurație inițială orientativă: 2 vCPU, 4 GB RAM, 40–80 GB SSD/NVMe și conexiune de rețea bună.
- Docker Compose pentru serviciile serverului.
- DNS dedicat pentru serviciile Aproxia.
- TLS/HTTPS pentru API și serviciile web.
- Monitorizare, loguri, backup și actualizări controlate.
- Clientul Aproxia trebuie configurat implicit să utilizeze infrastructura Aproxia, nu serverele publice RustDesk.

## 3. Audit de licențiere open-source

**Obligatoriu înainte de comercializare.**

Aproxia este construit pornind de la componente open-source RustDesk și alte biblioteci. Înainte de lansarea comercială trebuie verificat exact:

- AGPL-3.0 și obligațiile aplicabile clientului modificat.
- Licențele tuturor componentelor și dependențelor distribuite.
- Ce cod derivat trebuie făcut disponibil conform licenței.
- Ce componente backend/servicii Aproxia pot fi dezvoltate separat.
- Modul corect de afișare a copyright-ului, licențelor și atribuirilor.
- Pagina/fișierul `Open Source Licenses` care va însoți distribuția.

**Principiu:** brandingul comercial Aproxia poate fi propriu, dar nu eliminăm sau ascundem obligațiile legale ale componentelor open-source.

## 4. Conturi și sistem de licențiere Aproxia

Licențierea nu trebuie implementată doar local în client. Validarea și contorizarea trebuie făcute server-side pentru a evita resetarea limitei prin ștergerea fișierelor locale, schimbarea ceasului sau modificarea clientului.

Backend-ul Aproxia va gestiona:

- cont utilizator;
- autentificare;
- planul curent;
- abonamentul și starea plății;
- dispozitivele asociate;
- minutele utilizate/rămase;
- numărul de sesiuni simultane;
- activarea/dezactivarea funcțiilor premium;
- token-uri de sesiune/licență semnate;
- jurnal de utilizare pentru contorizare și diagnostic.

Clientul va primi de la API drepturile contului, de exemplu:

- plan: Free / Pro / Business;
- minute rămase;
- număr maxim de conexiuni simultane;
- funcții premium disponibile;
- data expirării/reînnoirii abonamentului.

Serverul trebuie să fie autoritatea finală pentru autorizarea funcțiilor comerciale.

## 5. Aproxia Free

Propunere inițială:

- **60 minute de utilizare remote pe lună**.
- **Maximum 1 sesiune/conexiune simultană**.
- Contorizarea minutelor pe server.
- Resetarea cotei la începutul fiecărei perioade lunare.
- În aplicație se afișează clar, de exemplu: `FREE · 43 min rămase`.
- La epuizarea celor 60 de minute, conexiunile remote noi sunt blocate și utilizatorul primește opțiunea de upgrade.
- Mesaj de upgrade simplu și neagresiv: `Ai utilizat cele 60 de minute incluse în Aproxia Free.`

Trebuie stabilit înainte de implementare dacă cele 60 de minute reprezintă timp total lunar de sesiune remote (varianta preferată) și cum se tratează sesiunile deja active în momentul epuizării cotei.

## 6. Aproxia Pro

**Preț orientativ inițial: 4,99 € / lună.**

Propunere:

- timp remote nelimitat;
- mai multe sesiuni simultane decât Free;
- mai multe dispozitive;
- funcții premium;
- administrarea dispozitivelor și favoritelor;
- experiență fără limitările Free.

Numărul exact de conexiuni și dispozitive incluse va fi stabilit după testarea infrastructurii și calcularea costurilor reale de relay/server.

În aplicație, statutul utilizatorului se schimbă automat din `FREE` în `PRO` după confirmarea abonamentului, fără instalarea unei alte versiuni Aproxia.

## 7. Aproxia Business — etapă ulterioară

Plan posibil pentru firme și echipe:

- mai multe conexiuni simultane;
- mai multe dispozitive administrate;
- agendă/address book centralizată;
- utilizatori/membri ai echipei;
- roluri și permisiuni;
- istoric și audit al conexiunilor;
- politici pentru dispozitive;
- eventual 2FA/SSO și funcții administrative avansate.

Prețul și limitele vor fi stabilite ulterior.

## 8. Plăți și abonamente

Direcția propusă: integrare cu un procesator de plăți pentru abonamente recurente (de exemplu Stripe Billing, după verificarea finală a costurilor și condițiilor comerciale).

Flux dorit:

1. Utilizatorul creează/intră în contul Aproxia.
2. Alege Aproxia Pro.
3. Plata se face prin pagina securizată a procesatorului.
4. Procesatorul trimite webhook către backend-ul Aproxia.
5. Backend-ul validează evenimentul și activează abonamentul.
6. Clientul Aproxia își actualizează automat drepturile.
7. Anulările, plățile eșuate și reînnoirile modifică automat statutul contului.

Nu se vor introduce chei secrete de plată în clientul desktop.

## 9. Protecția sistemului de abonamente

Sistemul trebuie proiectat astfel încât o modificare simplă a aplicației să nu ofere automat acces la serviciile premium.

Măsuri planificate:

- autorizare server-side;
- token-uri semnate și cu expirare;
- verificarea stării abonamentului pe backend;
- contorizarea minutelor pe backend;
- controlul sesiunilor simultane pe backend;
- webhook-uri de plată validate criptografic;
- rate limiting și protecția API;
- identificatori de dispozitiv proiectați cu grijă, fără colectare inutilă de date personale;
- HTTPS/TLS peste API;
- secretele și cheile private exclusiv pe infrastructura serverului;
- code signing Authenticode pentru executabilele Windows înainte de distribuția publică/comercială.

Checksum-ul SHA-256 al buildurilor este util pentru integritate, dar nu înlocuiește semnătura digitală Authenticode.

## 10. Versionare Aproxia și release-uri

Aproxia va avea propria schemă de versiuni, independentă de numărul versiunii upstream RustDesk afișat utilizatorului.

Vom folosi **Semantic Versioning** în forma `MAJOR.MINOR.PATCH`, plus etichete pentru buildurile de test.

Exemple:

- `Aproxia 0.1.0 Preview` — primele builduri Aproxia funcționale.
- `0.2.0 Preview` — modificare importantă de UI sau funcționalitate nouă.
- `0.2.1 Preview` — corecții de buguri fără funcționalitate majoră nouă.
- `0.5.0 Beta` — produs suficient de stabil pentru testare extinsă.
- `1.0.0` — prima versiune comercială/stabilă.
- `1.1.0` — funcționalitate nouă compatibilă cu 1.x.
- `1.1.1` — bugfix/hotfix.
- `2.0.0` — schimbare majoră incompatibilă sau generație nouă a produsului.

Reguli:

- **PATCH** crește pentru bugfix-uri, corecții de text/UI și remedieri mici.
- **MINOR** crește când adăugăm funcții importante: server Aproxia, conturi, licențe, address book, funcții Pro etc.
- **MAJOR** crește pentru generații majore sau schimbări incompatibile.
- Buildurile Preview/Beta vor afișa explicit stadiul lor.
- Numărul versiunii trebuie actualizat centralizat și propagat automat în pagina `Despre Aproxia`, metadatele Windows, installer, executabilul portable și, ulterior, mecanismul de update.
- Fiecare release trebuie să aibă changelog cu modificările principale.
- Versiunea upstream RustDesk poate fi păstrată numai în documentația tehnică/licențele open-source dacă este necesar, nu ca versiune comercială Aproxia în interfața utilizatorului.

## 11. Ordinea recomandată de implementare

1. Finalizare UI Aproxia și branding Windows.
2. Refacerea completă a Setărilor și paginii `Despre Aproxia`; eliminarea textelor/legăturilor RustDesk vizibile și localizarea completă în română.
3. Introducerea sistemului propriu de versionare Aproxia și propagarea versiunii în toate buildurile.
4. Repararea tuturor funcțiilor clientului și test remote real.
5. Stabilizarea `Aproxia-Portable-x64.exe` single-file.
6. Audit complet al licențelor open-source.
7. Instalarea infrastructurii self-hosted Aproxia.
8. Configurarea clientului pentru serverele Aproxia.
9. Backend de conturi și autentificare.
10. Backend de licențe și entitlement-uri.
11. Implementarea cotei Free de 60 minute/lună.
12. Limitarea Free la o singură conexiune simultană.
13. Implementarea Aproxia Pro.
14. Integrarea plăților și webhook-urilor.
15. UI pentru plan, minute rămase și upgrade.
16. Code signing și proces controlat de release/update.
17. Teste de securitate, abuz, concurență și recuperare după întreruperi.
18. Lansare Preview/Beta controlată.
19. După validare, lansare comercială.

## 12. Decizii actuale

La data de **11 septembrie 2026**, direcția agreată este:

- Produsul se numește **Aproxia**.
- Windows este prima platformă prioritară.
- Dorim client portabil single-file și posibilitate de instalare ca serviciu.
- Infrastructura finală va fi self-hosted Aproxia.
- Interfața va avea identitate proprie Aproxia și limba română implicită.
- Pagina de setări și `Despre` trebuie să fie Aproxia, nu RustDesk, iar atribuirea open-source va fi prezentată separat și legal corect.
- Aproxia va avea propria versionare Semantic Versioning, cu Preview/Beta înainte de `1.0.0` stabil.
- Model Free propus: **60 min/lună + 1 conexiune simultană**.
- Model Pro propus: **4,99 €/lună**, cu limitele finale de conexiuni/dispozitive de stabilit.
- Licențierea și limitele comerciale vor fi validate server-side.
- Înainte de comercializare se face auditul licențelor open-source.

---

### Notă de lucru

Acest fișier trebuie actualizat când luăm o decizie importantă de produs sau când finalizăm una dintre etape. Scopul lui este să putem relua dezvoltarea Aproxia fără să pierdem deciziile și ordinea de implementare stabilite.