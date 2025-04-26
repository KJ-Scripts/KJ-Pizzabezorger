Config = {}

Config.Locale = 'nl'
Config.JobName = 'pizzabezorger'

Config.PizzaShop = {
    blip = {
        coords = vector3(793.8792, -735.5715, 27.9631),
        sprite = 267,
        display = 4,
        scale = 0.7,
        color = 5,
        name = 'blip_shop'
    },
    bossNPC = {
        model = "s_m_y_chef_01",
        coords = vector4(793.8788, -735.5569, 27.9630, 88.3197),
    },
    scooterSpawnPoint = vector4(784.1877, -729.9321, 27.8349, 148.0690),
    scooterReturnPoint = vector3(784.1877, -729.9321, 27.8349),
    scooterModel = "faggio3",
    bailAmount = 500,
    returnMarker = {
        type = 2,
        scale = vector3(0.8, 0.8, 0.8),
        color = {r = 255, g = 165, b = 0, a = 200},
        rotate = false
    }
}

Config.Deliveries = {
    vector3(1303.0822, -527.4022, 71.4607),
    vector3(1328.5768, -535.9512, 72.4409),
    vector3(1373.3717, -555.5999, 74.6856),
    vector3(1386.1973, -593.5131, 74.4855),
    vector3(1341.2524, -597.4954, 74.7009),
    vector3(1241.2278, -566.2780, 69.6433),
    vector3(1240.5126, -601.6729, 69.7818),
    vector3(1250.5525, -621.0015, 69.5719),
    vector3(1265.5751, -648.6945, 68.1214),
    vector3(1264.6625, -702.7983, 64.9091),
    vector3(1229.6030, -725.4598, 60.9529),
    vector3(996.9827, -729.6818, 57.8157),
    vector3(979.2809, -716.3377, 58.2156),
    vector3(970.8214, -701.4213, 58.4820),
    vector3(959.9601, -669.9314, 58.4498),
    vector3(943.1844, -653.3546, 58.6261),
    vector3(500.5760, -1697.1299, 29.7893),
    vector3(489.6348, -1713.8892, 29.7069),
    vector3(472.1617, -1775.0764, 29.0707),
    vector3(500.5470, -1813.2875, 28.8912),
    vector3(427.4659, -1842.2986, 28.4634),
    vector3(512.5179, -1790.6864, 28.9193),
    vector3(484.2473, -1730.3876, 29.1984),
    vector3(-20.6224, -1859.0869, 25.4086),
    vector3(46.2253, -1864.4574, 23.2783),
    vector3(100.9739, -1912.2223, 21.4074),
    vector3(179.1283, -1923.8728, 21.3710),
    vector3(282.8147, -1899.0925, 27.2675),
    vector3(385.0733, -1881.5992, 26.0287)
}

Config.XPPerDelivery = 20
Config.RewardPerFactuur = 500

Config.Levels = {
    {level = 1, xp_required = 0, bonus_receipts = 0},
    {level = 2, xp_required = 100, bonus_receipts = 1},
    {level = 3, xp_required = 250, bonus_receipts = 2},
    {level = 4, xp_required = 500, bonus_receipts = 3},
    {level = 5, xp_required = 1000, bonus_receipts = 4},
    {level = 6, xp_required = 1500, bonus_receipts = 5},
    {level = 7, xp_required = 2250, bonus_receipts = 6},
    {level = 8, xp_required = 3000, bonus_receipts = 7},
    {level = 9, xp_required = 4000, bonus_receipts = 8},
    {level = 10, xp_required = 5000, bonus_receipts = 9}
}

Config.Locales = {
    ['nl'] = {
        ['job_title'] = 'Pizza Bezorger',
        ['blip_shop'] = 'Pizza Winkel',
        ['blip_delivery'] = 'Pizza Bezorging',
        ['menu_title'] = 'Pizza Winkel',
        ['menu_progress'] = 'Level: %s - XP: %s/%s',
        ['menu_rent_scooter'] = 'Huur Pizza Scooter (€%s)',
        ['menu_rent_scooter_desc'] = 'Huur een scooter om pizza\'s te bezorgen',
        ['menu_sell_receipts'] = 'Verkoop Bonnetjes',
        ['menu_sell_receipts_desc'] = 'Verkoop je pizza bonnetjes voor geld',
        ['menu_close'] = 'Sluiten',
        ['scooter_rented'] = 'Je hebt een pizza scooter gehuurd voor €%s',
        ['not_enough_money'] = 'Je hebt niet genoeg geld!',
        ['scooter_returned'] = 'Je hebt de scooter teruggebracht en je €%s borg teruggekregen',
        ['no_scooter_rented'] = 'Je hebt geen scooter gehuurd',
        ['receipts_sold'] = 'Je hebt %s bonnetjes verkocht voor €%s',
        ['no_receipts'] = 'Je hebt geen bonnetjes om te verkopen',
        ['delivery_complete'] = 'Bezorging voltooid! Je hebt een factuur en %s XP verdiend',
        ['level_up'] = 'Gefeliciteerd! Je hebt level %s bereikt',
        ['level_up_title'] = 'Level Omhoog!',
        ['preparing_pizza'] = 'Pizza uit scooter halen...',
        ['delivering_pizza'] = 'Pizza Bezorgen...',
        ['talk_to_boss'] = 'Praat met Baas',
        ['take_pizza'] = 'Pizza uit Scooter Halen',
        ['deliver_pizza'] = 'Pizza Bezorgen',
        ['return_scooter'] = 'Scooter Terugbrengen',
        ['xp_needed'] = 'Je hebt nog %s XP nodig om naar de volgende level te gaan.',
        ['new_delivery'] = 'Je hebt een nieuwe bezorging! Volg de route op je kaart.',
        ['scooter_not_close'] = 'De scooter moet dichter bij het afleverpunt zijn',
        ['player_not_close'] = 'Je moet dichter bij het afleverpunt zijn',
        ['no_active_delivery'] = 'Je hebt geen actieve bezorging of je hebt al een pizza in je handen',
        ['no_pizza_in_hand'] = 'Je hebt geen pizza in je handen',
        ['receipt_info'] = 'Dit is een factuur voor een geleverde pizza. Breng deze terug naar de pizzeria voor je beloning.'
    }
}
