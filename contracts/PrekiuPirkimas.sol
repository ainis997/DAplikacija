// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

struct Preke {
    string pav;
    uint kaina;
    uint likutis;
}

// pozicija čia = item
struct Pozicija {
    uint prekesID;
    uint kiekis;
    uint vntKaina;
}

// užsakymo būsena
enum Busena {
    Neuzsakyta,
    Uzsakyta,
    Patvirtinta,
    Pristatyta, // kurjerio pristatymo patvirtinimas
    Baigta, // kai klientas patvirtina gavimą
    Atsaukta
}

struct Uzsakymas {
    address pirkejas;
    address kurjeris;
    Pozicija[] pozicijos;
    uint suma; // bendra užsakymo suma
    Busena busena;
    uint sukurimoData;
}

contract PrekiuPirkimas {
    mapping(uint => Preke) public prekes; // pardavėjo visų prekių sąrašas (bus)
    mapping(uint => Uzsakymas) private uzsakymai; // visi esami užsakymai

    uint public prekesIdSkaitliukas = 1; // skaičiuosma nuo 1; 0 gali reikšt neesamą įrašą
    uint public uzsakymoIdSkaitliukas = 1; // skaičiuosma nuo 1; 0 gali reikšt neesamą įrašą

    address public pardavejas; // = kontrakto savininkas

    // vykdomas diegiant kontraktą blockchainan
    constructor() {
        pardavejas = msg.sender;
    }

    // ĮVYKIAI

    event PrekePrideta(uint indexed prekesID);
    event PrekeAtnaujinta(uint indexed prekesID);

    event PrekeNupirkta(address indexed pirkejas, uint suma);
    event UzsakymasPatvirtintas(address indexed kurjeris);
    event PristatymasPatvirtintas();
    event UzsakymasUzbaigtas();
    event UzsakymasAtsauktas();
    event MokejimasIvykdytas();
    event GrazinimasIvykdytas(address indexed pirkejas, uint suma);

    // MODIFIERIAI

    modifier TikPardavejas() {
        require(
            msg.sender == pardavejas,
            unicode"Funkciją gali kviesti tik pardavėjas."
        );
        _; // čia reiškia, kad nuo čia toliau eis modifikuotos fjos kodas (jei viskas ok)
    }

    modifier UzsakymasEgzistuoja(uint uzsakymoID) {
        // pabaigtina
    }

    // FUNKCIJOS

    // PREKIŲ VALDYMAS

    function pridetPreke(
        string memory pav,
        uint kaina,
        uint likutis
    ) external TikPardavejas returns (uint) {
        require(bytes(pav).length > 0, unicode"Nenurodytas prekės pavadinimas");
        require(kaina > 0, unicode"Kaina turi būti teigiama");
        // likutis gali būt ir 0

        uint id = prekesIdSkaitliukas;
        prekesIdSkaitliukas++;

        prekes[id] = Preke(pav, kaina, likutis); // pridedam prekę

        emit PrekePrideta(id);

        return id;
    }

    function atnaujintPreke(
        uint prekesID,
        string memory pav,
        uint kaina,
        uint likutis
    ) external TikPardavejas {
        require(
            prekesId > 0 && prekesID < prekesIdSkaitliukas,
            unicode"Prekė neegzistuoja"
        );
        require(bytes(pav).length > 0, unicode"Nenurodytas prekės pavadinimas");
        require(kaina > 0, unicode"Kaina turi būti teigiama");

        Preke storage p = prekes[prekesID]; // su storage gaunam, kad p — nuoroda tan mappingo elementan (prekėn)
        p.pav = pav;
        p.kaina = kaina;
        p.likutis = likutis;

        emit PrekeAtnaujinta(prekesID);
    }

    function pirktPreke() external payable {
        require(busena == Busena.Neuzsakyta, unicode"Prekė jau užsakyta");
        require(msg.sender != pardavejas, unicode"Pardavėjas pirkti negali");
        require(msg.value == kaina, unicode"Neatitinkanti mokėjimo suma"); // !!

        pirkejas = msg.sender;
        sumoketaSuma = msg.value;
        busena = Busena.Uzsakyta;

        emit PrekeNupirkta(pirkejas, sumoketaSuma);
    }

    function patvirtintUzsakyma(address _kurjeris) external TikPardavejas {
        require(busena == Busena.Uzsakyta, unicode"Negalima būsena");
        require(_kurjeris != address(0), unicode"Negalimas kurjeris");

        kurjeris = _kurjeris;
        busena = Busena.Patvirtinta;

        emit UzsakymasPatvirtintas(kurjeris);
    }

    function patvirtintPristatyma() external TikKurjeris {
        require(busena == Busena.Patvirtinta, unicode"Negalima būsena");

        busena = Busena.Pristatyta;

        emit PristatymasPatvirtintas();
    }

    function patvirtintGavima() external TikPirkejas {
        require(busena == Busena.Pristatyta, unicode"Prekė nepristatyta");

        busena = Busena.Baigta;

        emit UzsakymasUzbaigtas();
    }

    function atsauktUzsakyma() external TikPirkejas /** o pardavėjas? */ {
        require(busena == Busena.Uzsakyta, unicode"Negalima atšaukti užsakymo");

        busena = Busena.Atsaukta;

        emit UzsakymasAtsauktas();
    }

    function igytMokejima() external TikPardavejas {
        require(busena == Busena.Baigta, unicode"Užsakymas dar nebaigtas");
        require(sumoketaSuma > 0, unicode"Nėra įgyjamo mokėjimo");

        uint pasiimtinaSuma = sumoketaSuma;
        sumoketaSuma = 0; // nunulinam, kad pardavėjas negalėtų darkart pasiimt pinigų

        (bool arPavyko, ) = payable(pardavejas).call{value: pasiimtinaSuma}("");
        require(arPavyko, unicode"Mokėjimas nepavyko");

        emit MokejimasIvykdytas();
    }

    function grazintMokejima() external TikPirkejas {
        require(busena == Busena.Atsaukta, unicode"Užsakymas nėra atšauktas");
        require(sumoketaSuma > 0, unicode"Nėra ką grąžinti");

        uint grazintinaSuma = sumoketaSuma;
        sumoketaSuma = 0; // nunulinam, kad pirkėjas negalėtų darkart pasgrųžint pinigų

        (bool arPavyko, ) = payable(pirkejas).call{value: grazintinaSuma}("");
        require(arPavyko, unicode"Lėšų grąžinimas nepavyko");

        emit GrazinimasIvykdytas(pirkejas, grazintinaSuma);
    }
}
