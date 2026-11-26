// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract PrekiuPirkimas {
    // dalyviai
    address public pardavejas; // = kontrakto savininkas
    address public pirkejas;
    address public kurjeris;

    // prekės duomenys
    string public prekesPav;
    uint public kaina;

    // užsakymo būsena
    enum Busena {
        Neuzsakyta,
        Uzsakyta,
        Patvirtinta,
        Pristatyta, // kurjerio pristatymo patvirtinimas
        Baigta, // kai klientas patvirtina gavimą
        Atsaukta
    }

    Busena public busena;

    // kontraktan sumokėta suma (wei'ais)
    uint public sumoketaSuma;

    // vykdomas diegiant kontraktą blockchainan
    constructor(string memory _prekesPav, uint _kaina) {
        pardavejas = msg.sender;
        prekesPav = _prekesPav;
        kaina = _kaina;
        busena = Busena.Neuzsakyta;
    }

    // ĮVYKIAI

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

    modifier TikPirkejas() {
        require(
            msg.sender == pirkejas,
            unicode"Funkciją gali kviesti tik pirkėjas."
        );
        _;
    }

    modifier TikKurjeris() {
        require(
            msg.sender == kurjeris,
            unicode"Funkciją gali kviesti tik kurjeris."
        );
        _;
    }

    // FUNKCIJOS

    function pirktPreke() external payable {
        pirkejas = msg.sender;
        sumoketaSuma = msg.value;
        busena = Busena.Uzsakyta;

        emit PrekeNupirkta(pirkejas, sumoketaSuma);
    }

    function patvirtintUzsakyma(address _kurjeris) external TikPardavejas {
        kurjeris = _kurjeris;
        busena = Busena.Patvirtinta;

        emit UzsakymasPatvirtintas(kurjeris);
    }

    function patvirtintPristatyma() external TikKurjeris {
        busena = Busena.Pristatyta;

        emit PristatymasPatvirtintas();
    }

    function patvirtintGavima() external TikPirkejas {
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
