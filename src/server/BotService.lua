local BotService={}
local Config
local TerritoryService

-- First strategic country layer. Coordinates are normalized world positions.
-- Every entry is deterministic: a country always starts in the same region.
local COUNTRIES={
    {"Brasil",-51.9,-14.2},{"Estados Unidos",-98.6,39.8},{"Canada",-106.3,56.1},{"Mexico",-102.5,23.6},
    {"Argentina",-63.6,-38.4},{"Chile",-71.5,-35.7},{"Peru",-75.0,-9.2},{"Colombia",-74.3,4.6},{"Venezuela",-66.6,6.4},
    {"Bolivia",-63.6,-16.3},{"Paraguai",-58.4,-23.4},{"Uruguai",-55.8,-32.5},{"Equador",-78.2,-1.8},
    {"Portugal",-8.2,39.4},{"Espanha",-3.7,40.5},{"Franca",2.2,46.2},{"Reino Unido",-3.4,55.4},{"Irlanda",-8.2,53.4},
    {"Alemanha",10.4,51.2},{"Italia",12.6,41.9},{"Polonia",19.1,51.9},{"Ucrania",31.2,48.4},{"Russia",105.3,61.5},
    {"Turquia",35.2,39.0},{"Egito",30.8,26.8},{"Argelia",1.7,28.0},{"Marrocos",-7.1,31.8},{"Nigeria",8.7,9.1},
    {"Etiopia",40.5,9.1},{"Quenia",37.9,-0.0},{"Congo",21.8,-4.0},{"Angola",17.9,-11.2},{"Africa do Sul",22.9,-30.6},
    {"Arabia Saudita",45.1,23.9},{"Ira",53.7,32.4},{"Iraque",43.7,33.2},{"India",79.0,20.6},{"Paquistao",69.3,30.4},
    {"China",104.2,35.9},{"Mongolia",103.8,46.9},{"Japao",138.3,36.2},{"Coreia do Sul",127.8,35.9},
    {"Indonesia",113.9,-0.8},{"Filipinas",121.8,12.9},{"Australia",133.8,-25.3},{"Nova Zelandia",174.9,-40.9}
}

function BotService.Init(config,territoryService)
    Config=config
    TerritoryService=territoryService
end

function BotService.Start()
    -- Country agents are server-owned strategic actors. TerritoryService
    -- receives their fixed seeds after the map exists.
    TerritoryService.CreateCountryBots(COUNTRIES)
end
return BotService
