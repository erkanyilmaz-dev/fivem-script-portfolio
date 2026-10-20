local Translations = {
    error = {
        not_in_vehicle = "You must be inside a vehicle to perform this action!",
        must_be_driver = "You must be in the driver's seat to customize this vehicle!",
        cannot_afford = "Insufficient funds! You need $%s for this action.",
        not_mechanic = "You must be an authorized mechanic to use this workshop!",
        vehicle_not_found = "Vehicle not found!",
        already_repairing = "Vehicle is currently being repaired, please wait...",
        not_owner = "You do not own this vehicle, but changes have been temporarily applied.",
        society_cannot_afford = "Not enough funds in the mechanic society account!",
    },
    success = {
        installed = "%s successfully installed on vehicle!",
        purchased = "All modifications purchased and installed! Total: $%s",
        repaired = "Vehicle fully repaired and cleaned!",
        cleaned = "Vehicle washed and sparkling clean!",
        color_applied = "Respray job successfully completed!",
        saved = "Vehicle modifications saved successfully.",
    },
    info = {
        press_e_modify = "[E] - Enter Vater Mechanic Workshop",
        mechanic_bay = "Mechanic Bay",
        duty_off = "You are currently off duty!",
        invoice_sent = "Invoice sent to client.",
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
