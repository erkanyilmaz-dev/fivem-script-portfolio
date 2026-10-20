/* ============================================================================
   VATER PERFORMANCE - CORE INDUSTRIAL APPLICATION SCRIPT
   ============================================================================ */

let vehicleData = null;
let currentCategory = "performance";
let cart = {}; // key: modKey_val -> { title, price, modType, value, extraData }
let activeCameraPreset = "default";
let isMouseDown = false;
let startMouseX = 0, startMouseY = 0;
let currencySymbol = "$";
let currencyPosition = "right";

// ============================================================================
// AUDIO SYNTHESIZER (MUTED / SILENCED CLICK SOUNDS AS REQUESTED)
// ============================================================================
function playSound(type) {
    // Annoying chirp/click sounds muted completely
    return;
}

// ============================================================================
// FORMATTERS & NUI DISPATCHER
// ============================================================================
function formatPrice(amount) {
    amount = Number(amount) || 0;
    const formatted = amount.toLocaleString('tr-TR');
    if (currencyPosition === 'left') {
        return `${currencySymbol} ${formatted}`;
    }
    return `${formatted} ${currencySymbol}`;
}

function sendNui(event, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${event}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data)
    }).then(res => res.json()).catch(() => ({}));
}

// ============================================================================
// INITIALIZE & SYNC UI
// ============================================================================
function initUI(data, shopName, currency, currPos) {
    vehicleData = data;
    currencySymbol = currency || "$";
    currencyPosition = currPos || "right";
    cart = {};

    if (shopName) {
        document.getElementById("shop-location-name").textContent = shopName.toUpperCase();
    }

    const veh = data.vehicle;
    document.getElementById("veh-brand-text").textContent = (veh.brand || "CUSTOM").toUpperCase();
    document.getElementById("veh-name-text").textContent = (veh.label || "VEHICLE").toUpperCase();
    document.getElementById("veh-plate-text").textContent = veh.plate || "VATER";

    // Gauges
    const enginePct = Math.max(0, Math.min(100, Math.round(veh.stats.engine / 10)));
    const bodyPct = Math.max(0, Math.min(100, Math.round(veh.stats.body / 10)));

    document.getElementById("stat-engine-val").textContent = `${enginePct}%`;
    document.getElementById("stat-engine-bar").style.width = `${enginePct}%`;

    document.getElementById("stat-body-val").textContent = `${bodyPct}%`;
    document.getElementById("stat-body-bar").style.width = `${bodyPct}%`;

    document.getElementById("stat-speed-val").innerHTML = `${veh.stats.maxSpeed} <small>KM/H</small>`;

    updateCartDisplay();
    switchCategory("performance");
}

// ============================================================================
// CATEGORY NAVIGATION
// ============================================================================
function switchCategory(categoryKey) {
    currentCategory = categoryKey;

    document.querySelectorAll(".category-card").forEach(btn => {
        btn.classList.toggle("active", btn.dataset.category === categoryKey);
    });

    const subcategoryBar = document.getElementById("subcategory-bar");
    subcategoryBar.innerHTML = "";

    const container = document.getElementById("content-container");
    container.innerHTML = "";

    if (!vehicleData) return;

    if (categoryKey === "performance") {
        const perfMods = [
            { id: "11", name: "Motor", icon: "fa-fire" },
            { id: "12", name: "Frenler", icon: "fa-circle-stop" },
            { id: "13", name: "Şanzıman", icon: "fa-gears" },
            { id: "15", name: "Süspansiyon", icon: "fa-arrows-up-down" },
            { id: "16", name: "Zırh", icon: "fa-shield-halved" },
            { id: "turbo", name: "Turbo", icon: "fa-bolt-lightning" }
        ];

        perfMods.forEach((pm, index) => {
            const btn = document.createElement("button");
            btn.className = `sub-pill-btn ${index === 0 ? "active" : ""}`;
            btn.innerHTML = `<i class="fa-solid ${pm.icon}"></i> <span>${pm.name}</span>`;
            btn.onclick = () => {
                document.querySelectorAll(".sub-pill-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                renderPerformanceSubcategory(pm.id);
            };
            subcategoryBar.appendChild(btn);
        });

        renderPerformanceSubcategory(perfMods[0].id);
    } else if (categoryKey === "cosmetics") {
        const cosmModIds = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "42", "43", "25", "26"];
        const validMods = [];

        cosmModIds.forEach(id => {
            if (vehicleData.mods[id]) {
                validMods.push({ id: id, name: vehicleData.mods[id].category });
            }
        });

        if (validMods.length === 0) {
            container.innerHTML = `<div style="padding: 30px; text-align: center; color: var(--text-dim); font-size: 13px;">Bu araç için gövde kiti bulunmuyor.</div>`;
            return;
        }

        validMods.forEach((vm, index) => {
            const btn = document.createElement("button");
            btn.className = `sub-pill-btn ${index === 0 ? "active" : ""}`;
            btn.innerHTML = `<span>${vm.name}</span>`;
            btn.onclick = () => {
                document.querySelectorAll(".sub-pill-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                renderGenericModSubcategory(vm.id);
            };
            subcategoryBar.appendChild(btn);
        });

        renderGenericModSubcategory(validMods[0].id);
    } else if (categoryKey === "paint") {
        const paintTabs = [
            { id: "primary", name: "Gövde Rengi" },
            { id: "secondary", name: "İkincil Renk" },
            { id: "pearlescent", name: "Sedef / İnci" },
            { id: "wheel", name: "Jant Rengi" },
            { id: "dashboard", name: "Gösterge Paneli" },
            { id: "interior", name: "İç Döşeme" },
            { id: "custom_rgb", name: "Özel RGB Seçici" }
        ];

        paintTabs.forEach((pt, index) => {
            const btn = document.createElement("button");
            btn.className = `sub-pill-btn ${index === 0 ? "active" : ""}`;
            btn.innerHTML = `<span>${pt.name}</span>`;
            btn.onclick = () => {
                document.querySelectorAll(".sub-pill-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                renderPaintWorkshop(pt.id);
            };
            subcategoryBar.appendChild(btn);
        });

        renderPaintWorkshop("primary");
    } else if (categoryKey === "wheels") {
        const wheelTabs = [
            { id: "wheel_types", name: "Jant Modelleri" },
            { id: "stance", name: "Stance & Kamber" },
            { id: "tires", name: "Lastik Seçenekleri" },
            { id: "smoke", name: "Lastik Dumanı" }
        ];

        wheelTabs.forEach((wt, index) => {
            const btn = document.createElement("button");
            btn.className = `sub-pill-btn ${index === 0 ? "active" : ""}`;
            btn.innerHTML = `<span>${wt.name}</span>`;
            btn.onclick = () => {
                document.querySelectorAll(".sub-pill-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                renderWheelsSection(wt.id);
            };
            subcategoryBar.appendChild(btn);
        });

        renderWheelsSection("wheel_types");
    } else if (categoryKey === "lighting") {
        const lightTabs = [
            { id: "xenon", name: "Xenon Farlar" },
            { id: "underglow", name: "Alt Aydınlatma" }
        ];

        lightTabs.forEach((lt, index) => {
            const btn = document.createElement("button");
            btn.className = `sub-pill-btn ${index === 0 ? "active" : ""}`;
            btn.innerHTML = `<span>${lt.name}</span>`;
            btn.onclick = () => {
                document.querySelectorAll(".sub-pill-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                renderLightingSection(lt.id);
            };
            subcategoryBar.appendChild(btn);
        });

        renderLightingSection("xenon");
    } else if (categoryKey === "interior") {
        const interiorModIds = ["27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "44", "horns", "tints", "plates"];
        const validTabs = [];

        interiorModIds.forEach(id => {
            if (id === "horns") {
                validTabs.push({ id: "horns", name: "Kornalar" });
            } else if (id === "tints") {
                validTabs.push({ id: "tints", name: "Cam Filmleri" });
            } else if (id === "plates") {
                validTabs.push({ id: "plates", name: "Plaka Stilleri" });
            } else if (vehicleData.mods[id]) {
                validTabs.push({ id: id, name: vehicleData.mods[id].category });
            }
        });

        validTabs.forEach((vt, index) => {
            const btn = document.createElement("button");
            btn.className = `sub-pill-btn ${index === 0 ? "active" : ""}`;
            btn.innerHTML = `<span>${vt.name}</span>`;
            btn.onclick = () => {
                document.querySelectorAll(".sub-pill-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                if (vt.id === "horns" || vt.id === "tints" || vt.id === "plates") {
                    renderMiscSection(vt.id);
                } else {
                    renderGenericModSubcategory(vt.id);
                }
            };
            subcategoryBar.appendChild(btn);
        });

        if (validTabs.length > 0) {
            if (validTabs[0].id === "horns" || validTabs[0].id === "tints" || validTabs[0].id === "plates") {
                renderMiscSection(validTabs[0].id);
            } else {
                renderGenericModSubcategory(validTabs[0].id);
            }
        }
    } else if (categoryKey === "extras") {
        const extraTabs = [
            { id: "extras_list", name: "Ekstra Parçalar" },
            { id: "livery", name: "Gövde Kaplamaları" }
        ];

        extraTabs.forEach((et, index) => {
            const btn = document.createElement("button");
            btn.className = `sub-pill-btn ${index === 0 ? "active" : ""}`;
            btn.innerHTML = `<span>${et.name}</span>`;
            btn.onclick = () => {
                document.querySelectorAll(".sub-pill-btn").forEach(b => b.classList.remove("active"));
                btn.classList.add("active");
                renderExtrasAndLivery(et.id);
            };
            subcategoryBar.appendChild(btn);
        });

        renderExtrasAndLivery("extras_list");
    } else if (categoryKey === "service") {
        renderServiceSection();
    }
}

// ============================================================================
// CONTENT RENDERERS
// ============================================================================

// 1. Performance Subcategory (Matte Card + Clean Step Dots)
function renderPerformanceSubcategory(modId) {
    const container = document.getElementById("content-container");
    container.innerHTML = "";

    if (modId === "turbo") {
        focusCameraAuto("engine");
        const turboData = vehicleData.turbo;
        const grid = document.createElement("div");
        grid.className = "parts-grid-industrial";

        turboData.items.forEach(item => {
            const isInstalled = item.installed;
            const isCart = isItemInCart("turbo", item.index);

            const card = document.createElement("div");
            card.className = `industrial-card ${isInstalled ? "installed" : ""} ${isCart ? "selected" : ""}`;
            card.innerHTML = `
                <div class="card-headline-row">
                    <span class="part-name-text">${item.name}</span>
                    <span class="flat-badge ${isInstalled ? "badge-installed" : isCart ? "badge-cart" : "badge-level"}">
                        ${isInstalled ? "TAKILI" : isCart ? "SEPETTE" : "BOOST"}
                    </span>
                </div>
                <div class="stage-dots-bar">
                    <div class="stage-dot ${item.index === 1 ? "filled" : ""}"></div>
                    <div class="stage-dot ${item.index === 1 ? "filled" : ""}"></div>
                    <div class="stage-dot ${item.index === 1 ? "filled" : ""}"></div>
                </div>
                <div class="card-footer-row">
                    <span class="part-price-tag ${item.price === 0 ? "free" : ""}">${item.price === 0 ? "ÜCRETSİZ" : formatPrice(item.price)}</span>
                    <div class="action-icon-box"><i class="fa-solid ${isInstalled ? "fa-check" : "fa-wrench"}"></i></div>
                </div>
            `;

            card.onclick = () => {
                sendNui("previewMod", { modType: "turbo", value: item.index });
                if (!isInstalled) {
                    toggleCartItem("turbo", item.index, {
                        title: `Turbo: ${item.name}`,
                        price: item.price,
                        modType: "turbo",
                        value: item.index
                    });
                }
                renderPerformanceSubcategory("turbo");
            };
            grid.appendChild(card);
        });

        container.appendChild(grid);
        return;
    }

    const modData = vehicleData.mods[modId];
    if (!modData) {
        container.innerHTML = `<div style="padding: 30px; text-align: center; color: var(--text-dim); font-size: 13px;">Bu parça mevcut değil.</div>`;
        return;
    }

    focusCameraAuto(modData.focus || "engine");

    const grid = document.createElement("div");
    grid.className = "parts-grid-industrial";

    const totalCount = modData.items.length - 1;

    modData.items.forEach(item => {
        const isInstalled = item.installed;
        const isCart = isItemInCart(`mod_${modId}`, item.index);
        const stageIndex = item.index + 1;

        let dotsHtml = `<div class="stage-dots-bar">`;
        for (let l = 1; l <= Math.max(4, totalCount); l++) {
            dotsHtml += `<div class="stage-dot ${stageIndex >= l ? "filled" : ""}"></div>`;
        }
        dotsHtml += `</div>`;

        const card = document.createElement("div");
        card.className = `industrial-card ${isInstalled ? "installed" : ""} ${isCart ? "selected" : ""}`;
        card.innerHTML = `
            <div class="card-headline-row">
                <span class="part-name-text">${item.name}</span>
                <span class="flat-badge ${isInstalled ? "badge-installed" : isCart ? "badge-cart" : item.index === -1 ? "badge-stock" : "badge-level"}">
                    ${isInstalled ? "TAKILI" : isCart ? "SEPETTE" : item.index === -1 ? "STOCK" : "SEVİYE " + stageIndex}
                </span>
            </div>
            ${dotsHtml}
            <div class="card-footer-row">
                <span class="part-price-tag ${item.price === 0 ? "free" : ""}">${item.price === 0 ? "ÜCRETSİZ" : formatPrice(item.price)}</span>
                <div class="action-icon-box"><i class="fa-solid ${isInstalled ? "fa-check" : "fa-wrench"}"></i></div>
            </div>
        `;

        card.onclick = () => {
            sendNui("previewMod", { modType: "mod", value: item.index, extraData: { id: modId } });
            if (!isInstalled) {
                toggleCartItem(`mod_${modId}`, item.index, {
                    title: `${modData.category}: ${item.name}`,
                    price: item.price,
                    modType: "mod",
                    value: item.index,
                    extraData: { id: modId }
                });
            }
            renderPerformanceSubcategory(modId);
        };
        grid.appendChild(card);
    });

    container.appendChild(grid);
}

// 2. Generic Mod Subcategory
function renderGenericModSubcategory(modId) {
    const container = document.getElementById("content-container");
    container.innerHTML = "";

    const modData = vehicleData.mods[modId];
    if (!modData) return;

    focusCameraAuto(modData.focus || "default");

    const grid = document.createElement("div");
    grid.className = "parts-grid-industrial";

    modData.items.forEach(item => {
        const isInstalled = item.installed;
        const isCart = isItemInCart(`mod_${modId}`, item.index);

        const card = document.createElement("div");
        card.className = `industrial-card ${isInstalled ? "installed" : ""} ${isCart ? "selected" : ""}`;
        card.innerHTML = `
            <div class="card-headline-row">
                <span class="part-name-text">${item.name}</span>
                <span class="flat-badge ${isInstalled ? "badge-installed" : isCart ? "badge-cart" : item.index === -1 ? "badge-stock" : "badge-level"}">
                    ${isInstalled ? "TAKILI" : isCart ? "SEPETTE" : item.index === -1 ? "STOCK" : "PARÇA #" + (item.index + 1)}
                </span>
            </div>
            <div class="card-footer-row">
                <span class="part-price-tag ${item.price === 0 ? "free" : ""}">${item.price === 0 ? "ÜCRETSİZ" : formatPrice(item.price)}</span>
                <div class="action-icon-box"><i class="fa-solid ${isInstalled ? "fa-check" : "fa-wrench"}"></i></div>
            </div>
        `;

        card.onclick = () => {
            sendNui("previewMod", { modType: "mod", value: item.index, extraData: { id: modId } });
            if (!isInstalled) {
                toggleCartItem(`mod_${modId}`, item.index, {
                    title: `${modData.category}: ${item.name}`,
                    price: item.price,
                    modType: "mod",
                    value: item.index,
                    extraData: { id: modId }
                });
            }
            renderGenericModSubcategory(modId);
        };
        grid.appendChild(card);
    });

    container.appendChild(grid);
}

// 3. Paint Workshop
function renderPaintWorkshop(paintType) {
    const container = document.getElementById("content-container");
    container.innerHTML = "";

    focusCameraAuto(paintType === "wheel" ? "wheel_front" : paintType === "interior" || paintType === "dashboard" ? "interior" : "default");

    const wrapper = document.createElement("div");
    wrapper.className = "color-workshop-stack";

    if (paintType === "custom_rgb") {
        wrapper.innerHTML = `
            <div class="rgb-solid-card">
                <div class="color-category-title"><i class="fa-solid fa-palette"></i> Özel RGB Gövde Rengi</div>
                <div class="rgb-slider-item">
                    <span class="rgb-tag r">R</span>
                    <input type="range" class="matte-slider" id="rgb-r" min="0" max="255" value="0">
                    <span class="rgb-num-label" id="rgb-r-val">0</span>
                </div>
                <div class="rgb-slider-item">
                    <span class="rgb-tag g">G</span>
                    <input type="range" class="matte-slider" id="rgb-g" min="0" max="255" value="180">
                    <span class="rgb-num-label" id="rgb-g-val">180</span>
                </div>
                <div class="rgb-slider-item">
                    <span class="rgb-tag b">B</span>
                    <input type="range" class="matte-slider" id="rgb-b" min="0" max="255" value="255">
                    <span class="rgb-num-label" id="rgb-b-val">255</span>
                </div>
                <button class="flat-btn btn-primary" id="apply-rgb-cart-btn" style="margin-top: 6px; justify-content: center;">
                    <i class="fa-solid fa-cart-plus"></i>
                    <span>Özel RGB Rengini Sepete Ekle (${formatPrice(vehicleData.prices.paint.customRGB || 2200)})</span>
                </button>
            </div>
        `;
        container.appendChild(wrapper);

        const rSlider = document.getElementById("rgb-r");
        const gSlider = document.getElementById("rgb-g");
        const bSlider = document.getElementById("rgb-b");

        const updateRGB = () => {
            const r = parseInt(rSlider.value);
            const g = parseInt(gSlider.value);
            const b = parseInt(bSlider.value);
            document.getElementById("rgb-r-val").textContent = r;
            document.getElementById("rgb-g-val").textContent = g;
            document.getElementById("rgb-b-val").textContent = b;

            sendNui("previewMod", {
                modType: "paint_rgb",
                value: { r, g, b },
                extraData: { paintType: "primary" }
            });
        };

        rSlider.oninput = updateRGB;
        gSlider.oninput = updateRGB;
        bSlider.oninput = updateRGB;

        document.getElementById("apply-rgb-cart-btn").onclick = () => {
            const r = parseInt(rSlider.value);
            const g = parseInt(gSlider.value);
            const b = parseInt(bSlider.value);
            toggleCartItem("paint_custom_rgb", `${r}_${g}_${b}`, {
                title: `Özel RGB Boya (RGB: ${r}, ${g}, ${b})`,
                price: vehicleData.prices.paint.customRGB || 2200,
                modType: "paint_rgb",
                value: { r, g, b },
                extraData: { paintType: "primary" }
            });
        };
        return;
    }

    const colorsObj = vehicleData.paint.colors || {};

    Object.keys(colorsObj).forEach(catName => {
        const group = document.createElement("div");
        group.className = "color-category-block";

        const label = document.createElement("div");
        label.className = "color-category-title";
        label.textContent = catName;
        group.appendChild(label);

        const grid = document.createElement("div");
        grid.className = "color-chips-matrix";

        colorsObj[catName].forEach(color => {
            const isCart = isItemInCart(`paint_${paintType}`, color.index);

            const chip = document.createElement("div");
            chip.className = `color-sample-box ${isCart ? "active" : ""}`;
            chip.innerHTML = `
                <div class="color-swatch-circle" style="background: ${getColorPreviewHex(color.name, catName)};"></div>
                <span class="color-swatch-text">${color.name}</span>
            `;

            chip.onclick = () => {
                sendNui("previewMod", {
                    modType: "paint_classic",
                    value: color.index,
                    extraData: { paintType: paintType }
                });

                const price = vehicleData.prices.paint[paintType] || 1200;
                toggleCartItem(`paint_${paintType}`, color.index, {
                    title: `Boya (${paintType}): ${color.name}`,
                    price: price,
                    modType: "paint_classic",
                    value: color.index,
                    extraData: { paintType: paintType }
                });
                renderPaintWorkshop(paintType);
            };

            grid.appendChild(chip);
        });

        group.appendChild(grid);
        wrapper.appendChild(group);
    });

    container.appendChild(wrapper);
}

function getColorPreviewHex(name, category) {
    name = name.toLowerCase();
    if (name.includes("siyah")) return "#0c0d10";
    if (name.includes("beyaz")) return "#e2e8f0";
    if (name.includes("kırmızı") || name.includes("bordo")) return "#b91c1c";
    if (name.includes("mavi") || name.includes("turkuaz")) return "#0369a1";
    if (name.includes("yeşil") || name.includes("haki")) return "#15803d";
    if (name.includes("sarı") || name.includes("altın")) return "#ca8a04";
    if (name.includes("turuncu") || name.includes("bakır")) return "#c2410c";
    if (name.includes("mor") || name.includes("pembe")) return "#7e22ce";
    if (name.includes("krom")) return "#cbd5e1";
    if (name.includes("çelik") || name.includes("gümüş")) return "#475569";
    return "#334155";
}

// 4. Wheels Section
function renderWheelsSection(tabId) {
    const container = document.getElementById("content-container");
    container.innerHTML = "";

    focusCameraAuto("wheel_front");

    if (tabId === "wheel_types") {
        const categories = vehicleData.wheels.categories || [];
        const selector = document.createElement("div");
        selector.className = "sub-tabs-container";
        selector.style.marginBottom = "12px";

        categories.forEach((cat, idx) => {
            const chip = document.createElement("button");
            chip.className = `sub-pill-btn ${idx === 0 ? "active" : ""}`;
            chip.textContent = cat.name;
            chip.onclick = () => {
                document.querySelectorAll("#content-container .sub-pill-btn").forEach(c => c.classList.remove("active"));
                chip.classList.add("active");
                renderWheelRimsGrid(cat.id);
            };
            selector.appendChild(chip);
        });

        container.appendChild(selector);

        const rimsContainer = document.createElement("div");
        rimsContainer.id = "rims-grid-container";
        container.appendChild(rimsContainer);

        renderWheelRimsGrid(categories[0].id);
    } else if (tabId === "stance") {
        const stanceBox = document.createElement("div");
        stanceBox.className = "stance-workbench-box";
        stanceBox.innerHTML = `
            <div class="stance-slider-card-box">
                <div class="stance-card-topbar">
                    <span class="stance-card-label"><i class="fa-solid fa-arrows-left-right"></i> Jant Genişliği</span>
                    <span class="stance-numeric-pill" id="stance-width-val">100%</span>
                </div>
                <input type="range" class="matte-slider" id="slider-wheel-width" min="50" max="200" value="100">
            </div>

            <div class="stance-slider-card-box">
                <div class="stance-card-topbar">
                    <span class="stance-card-label"><i class="fa-solid fa-maximize"></i> Jant Boyutu</span>
                    <span class="stance-numeric-pill" id="stance-size-val">100%</span>
                </div>
                <input type="range" class="matte-slider" id="slider-wheel-size" min="50" max="150" value="100">
            </div>

            <div class="stance-slider-card-box">
                <div class="stance-card-topbar">
                    <span class="stance-card-label"><i class="fa-solid fa-angles-down"></i> Kamber Açısı (Stance)</span>
                    <span class="stance-numeric-pill" id="stance-camber-val">0°</span>
                </div>
                <input type="range" class="matte-slider" id="slider-camber" min="-25" max="25" value="0">
            </div>
        `;
        container.appendChild(stanceBox);

        const widthSlider = document.getElementById("slider-wheel-width");
        const sizeSlider = document.getElementById("slider-wheel-size");
        const camberSlider = document.getElementById("slider-camber");

        const updateStance = () => {
            const w = widthSlider.value;
            const s = sizeSlider.value;
            const c = camberSlider.value;
            document.getElementById("stance-width-val").textContent = `${w}%`;
            document.getElementById("stance-size-val").textContent = `${s}%`;
            document.getElementById("stance-camber-val").textContent = `${c}°`;

            sendNui("previewMod", {
                modType: "stance",
                value: 0,
                extraData: { width: w, size: s, camber: c }
            });
        };

        widthSlider.oninput = updateStance;
        sizeSlider.oninput = updateStance;
        camberSlider.oninput = updateStance;
    } else if (tabId === "tires") {
        const grid = document.createElement("div");
        grid.className = "parts-grid-industrial";

        const tireOptions = [
            { id: "custom_tires", name: "Özel Tasarım Lastik Yazısı", price: vehicleData.prices.wheels.customTires || 1200 },
            { id: "drift_tires", name: "Özel Drift / Kayma Lastikleri", price: vehicleData.prices.wheels.driftTires || 3000 },
            { id: "bulletproof_tires", name: "Kurşun Geçirmez Çelik Lastikler", price: vehicleData.prices.wheels.bulletproofTires || 8500 }
        ];

        tireOptions.forEach(opt => {
            const isCart = isItemInCart("tires", opt.id);
            const card = document.createElement("div");
            card.className = `industrial-card ${isCart ? "selected" : ""}`;
            card.innerHTML = `
                <div class="card-headline-row">
                    <span class="part-name-text">${opt.name}</span>
                    <span class="flat-badge ${isCart ? "badge-cart" : "badge-level"}">${isCart ? "SEPETTE" : "OPSİYON"}</span>
                </div>
                <div class="card-footer-row">
                    <span class="part-price-tag">${formatPrice(opt.price)}</span>
                    <div class="action-icon-box"><i class="fa-solid fa-wrench"></i></div>
                </div>
            `;

            card.onclick = () => {
                sendNui("previewMod", { modType: opt.id, value: 1 });
                toggleCartItem("tires", opt.id, {
                    title: `Lastik: ${opt.name}`,
                    price: opt.price,
                    modType: opt.id,
                    value: 1
                });
                renderWheelsSection("tires");
            };
            grid.appendChild(card);
        });

        container.appendChild(grid);
    } else if (tabId === "smoke") {
        const smokeBox = document.createElement("div");
        smokeBox.className = "rgb-solid-card";
        smokeBox.innerHTML = `
            <div class="color-category-title"><i class="fa-solid fa-smog"></i> RGB Lastik Dumanı Rengi</div>
            <div class="rgb-slider-item">
                <span class="rgb-tag r">R</span>
                <input type="range" class="matte-slider" id="smoke-r" min="0" max="255" value="255">
                <span class="rgb-num-label" id="smoke-r-val">255</span>
            </div>
            <div class="rgb-slider-item">
                <span class="rgb-tag g">G</span>
                <input type="range" class="matte-slider" id="smoke-g" min="0" max="255" value="0">
                <span class="rgb-num-label" id="smoke-g-val">0</span>
            </div>
            <div class="rgb-slider-item">
                <span class="rgb-tag b">B</span>
                <input type="range" class="matte-slider" id="smoke-b" min="0" max="255" value="128">
                <span class="rgb-num-label" id="smoke-b-val">128</span>
            </div>
            <button class="flat-btn btn-primary" id="apply-smoke-cart-btn" style="margin-top: 6px; justify-content: center;">
                <i class="fa-solid fa-cart-plus"></i>
                <span>Duman Rengini Sepete Ekle (${formatPrice(vehicleData.prices.wheels.tireSmoke || 1500)})</span>
            </button>
        `;
        container.appendChild(smokeBox);

        const rSlider = document.getElementById("smoke-r");
        const gSlider = document.getElementById("smoke-g");
        const bSlider = document.getElementById("smoke-b");

        const updateSmoke = () => {
            const r = parseInt(rSlider.value);
            const g = parseInt(gSlider.value);
            const b = parseInt(bSlider.value);
            document.getElementById("smoke-r-val").textContent = r;
            document.getElementById("smoke-g-val").textContent = g;
            document.getElementById("smoke-b-val").textContent = b;

            sendNui("previewMod", {
                modType: "paint_rgb",
                value: { r, g, b },
                extraData: { paintType: "smoke" }
            });
        };

        rSlider.oninput = updateSmoke;
        gSlider.oninput = updateSmoke;
        bSlider.oninput = updateSmoke;

        document.getElementById("apply-smoke-cart-btn").onclick = () => {
            const r = parseInt(rSlider.value);
            const g = parseInt(gSlider.value);
            const b = parseInt(bSlider.value);
            toggleCartItem("tire_smoke_rgb", `${r}_${g}_${b}`, {
                title: `Lastik Dumanı (RGB: ${r}, ${g}, ${b})`,
                price: vehicleData.prices.wheels.tireSmoke || 1500,
                modType: "paint_rgb",
                value: { r, g, b },
                extraData: { paintType: "smoke" }
            });
        };
    }
}

function renderWheelRimsGrid(typeId, cachedCount) {
    const container = document.getElementById("rims-grid-container");
    if (!container) return;

    const buildGrid = (totalRims) => {
        container.innerHTML = "";
        const grid = document.createElement("div");
        grid.className = "parts-grid-industrial";

        // Stock
        const stockCard = document.createElement("div");
        stockCard.className = "industrial-card";
        stockCard.innerHTML = `
            <div class="card-headline-row">
                <span class="part-name-text">Standart Jant (Stock)</span>
                <span class="flat-badge badge-stock">STOCK</span>
            </div>
            <div class="card-footer-row">
                <span class="part-price-tag free">ÜCRETSİZ</span>
                <div class="action-icon-box"><i class="fa-solid fa-wrench"></i></div>
            </div>
        `;
        stockCard.onclick = () => {
            sendNui("previewMod", { modType: "wheel_mod", value: -1, extraData: { wheelType: typeId } });
        };
        grid.appendChild(stockCard);

        for (let i = 0; i < totalRims; i++) {
            const isCart = isItemInCart(`wheel_${typeId}`, i);
            const card = document.createElement("div");
            card.className = `industrial-card ${isCart ? "selected" : ""}`;
            card.innerHTML = `
                <div class="card-headline-row">
                    <span class="part-name-text">Jant Modeli #${i + 1}</span>
                    <span class="flat-badge ${isCart ? "badge-cart" : "badge-level"}">${isCart ? "SEPETTE" : "JANT"}</span>
                </div>
                <div class="card-footer-row">
                    <span class="part-price-tag">${formatPrice(vehicleData.prices.wheels.type || 2000)}</span>
                    <div class="action-icon-box"><i class="fa-solid fa-wrench"></i></div>
                </div>
            `;

            card.onclick = () => {
                sendNui("previewMod", { modType: "wheel_mod", value: i, extraData: { wheelType: typeId } });
                toggleCartItem(`wheel_${typeId}`, i, {
                    title: `Jant: Model #${i + 1}`,
                    price: vehicleData.prices.wheels.type || 2000,
                    modType: "wheel_mod",
                    value: i,
                    extraData: { wheelType: typeId }
                });
                renderWheelRimsGrid(typeId, totalRims);
            };
            grid.appendChild(card);
        }

        container.appendChild(grid);
    };

    if (typeof cachedCount === 'number') {
        buildGrid(cachedCount);
    } else {
        container.innerHTML = "";
        sendNui("previewMod", { modType: "wheel_type", value: typeId }).then(res => {
            const totalRims = (res && typeof res.wheelCount === 'number' && res.wheelCount > 0) ? res.wheelCount : 45;
            buildGrid(totalRims);
        });
    }
}

// 5. Lighting Section
function renderLightingSection(tabId) {
    const container = document.getElementById("content-container");
    container.innerHTML = "";

    if (tabId === "xenon") {
        focusCameraAuto("xenon");
        const list = vehicleData.xenon.list || [];
        const grid = document.createElement("div");
        grid.className = "parts-grid-industrial";

        list.forEach(item => {
            const isInstalled = item.installed;
            const isCart = isItemInCart("xenon", item.id);

            const card = document.createElement("div");
            card.className = `industrial-card ${isInstalled ? "installed" : ""} ${isCart ? "selected" : ""}`;
            card.innerHTML = `
                <div class="card-headline-row">
                    <span class="part-name-text">${item.name}</span>
                    <span class="flat-badge ${isInstalled ? "badge-installed" : isCart ? "badge-cart" : "badge-level"}">
                        ${isInstalled ? "TAKILI" : isCart ? "SEPETTE" : "XENON"}
                    </span>
                </div>
                <div class="card-footer-row">
                    <span class="part-price-tag">${formatPrice(item.price)}</span>
                    <div class="action-icon-box"><i class="fa-solid fa-lightbulb"></i></div>
                </div>
            `;

            card.onclick = () => {
                sendNui("previewMod", { modType: "xenon", value: item.id });
                if (!isInstalled) {
                    toggleCartItem("xenon", item.id, {
                        title: `Xenon Far: ${item.name}`,
                        price: item.price,
                        modType: "xenon",
                        value: item.id
                    });
                }
                renderLightingSection("xenon");
            };
            grid.appendChild(card);
        });

        container.appendChild(grid);
    } else if (tabId === "underglow") {
        focusCameraAuto("underglow");
        const neonBox = document.createElement("div");
        neonBox.className = "stance-workbench-box";

        const sides = [
            { side: 0, name: "Sol Alt Aydınlatma" },
            { side: 1, name: "Sağ Alt Aydınlatma" },
            { side: 2, name: "Ön Alt Aydınlatma" },
            { side: 3, name: "Arka Alt Aydınlatma" }
        ];

        sides.forEach(s => {
            const card = document.createElement("div");
            card.className = "switch-control-card";
            card.innerHTML = `
                <div class="switch-details">
                    <span class="switch-main-label">${s.name}</span>
                    <span class="switch-price-label">${formatPrice(875)}</span>
                </div>
                <label class="matte-switch">
                    <input type="checkbox" id="neon-toggle-${s.side}">
                    <span class="switch-slider"></span>
                </label>
            `;
            neonBox.appendChild(card);
        });

        const colorBox = document.createElement("div");
        colorBox.className = "rgb-solid-card";
        colorBox.innerHTML = `
            <div class="color-category-title"><i class="fa-solid fa-palette"></i> Alt Işık Rengi (RGB)</div>
            <div class="rgb-slider-item">
                <span class="rgb-tag r">R</span>
                <input type="range" class="matte-slider" id="neon-r" min="0" max="255" value="255">
                <span class="rgb-num-label" id="neon-r-val">255</span>
            </div>
            <div class="rgb-slider-item">
                <span class="rgb-tag g">G</span>
                <input type="range" class="matte-slider" id="neon-g" min="0" max="255" value="85">
                <span class="rgb-num-label" id="neon-g-val">85</span>
            </div>
            <div class="rgb-slider-item">
                <span class="rgb-tag b">B</span>
                <input type="range" class="matte-slider" id="neon-b" min="0" max="255" value="0">
                <span class="rgb-num-label" id="neon-b-val">0</span>
            </div>
            <button class="flat-btn btn-primary" id="apply-neon-cart-btn" style="margin-top: 6px; justify-content: center;">
                <i class="fa-solid fa-cart-plus"></i>
                <span>Komple Alt Işık Kitini Ekle (${formatPrice(vehicleData.prices.lighting.neonSet || 3500)})</span>
            </button>
        `;
        neonBox.appendChild(colorBox);
        container.appendChild(neonBox);

        sides.forEach(s => {
            const el = document.getElementById(`neon-toggle-${s.side}`);
            el.onchange = () => {
                sendNui("previewMod", {
                    modType: "neon_toggle",
                    value: el.checked ? 1 : 0,
                    extraData: { side: s.side }
                });
            };
        });

        const nrSlider = document.getElementById("neon-r");
        const ngSlider = document.getElementById("neon-g");
        const nbSlider = document.getElementById("neon-b");

        const updateNeonColor = () => {
            const r = parseInt(nrSlider.value);
            const g = parseInt(ngSlider.value);
            const b = parseInt(nbSlider.value);
            document.getElementById("neon-r-val").textContent = r;
            document.getElementById("neon-g-val").textContent = g;
            document.getElementById("neon-b-val").textContent = b;

            sides.forEach(s => {
                document.getElementById(`neon-toggle-${s.side}`).checked = true;
                sendNui("previewMod", { modType: "neon_toggle", value: 1, extraData: { side: s.side } });
            });

            sendNui("previewMod", {
                modType: "neon_color",
                value: { r, g, b }
            });
        };

        nrSlider.oninput = updateNeonColor;
        ngSlider.oninput = updateNeonColor;
        nbSlider.oninput = updateNeonColor;

        document.getElementById("apply-neon-cart-btn").onclick = () => {
            const r = parseInt(nrSlider.value);
            const g = parseInt(ngSlider.value);
            const b = parseInt(nbSlider.value);
            toggleCartItem("neon_set", "full", {
                title: `Alt Işık Kiti (RGB: ${r}, ${g}, ${b})`,
                price: vehicleData.prices.lighting.neonSet || 3500,
                modType: "neon_set",
                value: { r, g, b }
            });
        };
    }
}

// 6. Misc Section (Horns, Tints, Plates)
function renderMiscSection(tabId) {
    const container = document.getElementById("content-container");
    container.innerHTML = "";

    if (tabId === "tints") {
        focusCameraAuto("side");
        const list = vehicleData.tints.list || [];
        const grid = document.createElement("div");
        grid.className = "parts-grid-industrial";

        list.forEach(item => {
            const isInstalled = vehicleData.tints.current === item.id;
            const isCart = isItemInCart("window_tint", item.id);

            const card = document.createElement("div");
            card.className = `industrial-card ${isInstalled ? "installed" : ""} ${isCart ? "selected" : ""}`;
            card.innerHTML = `
                <div class="card-headline-row">
                    <span class="part-name-text">${item.name}</span>
                    <span class="flat-badge ${isInstalled ? "badge-installed" : isCart ? "badge-cart" : "badge-level"}">${isInstalled ? "TAKILI" : isCart ? "SEPETTE" : "CAM FİLMİ"}</span>
                </div>
                <div class="card-footer-row">
                    <span class="part-price-tag">${formatPrice(vehicleData.prices.miscellaneous.windowTint || 950)}</span>
                    <div class="action-icon-box"><i class="fa-solid fa-eye-slash"></i></div>
                </div>
            `;
            card.onclick = () => {
                sendNui("previewMod", { modType: "window_tint", value: item.id });
                toggleCartItem("window_tint", item.id, {
                    title: `Cam Filmi: ${item.name}`,
                    price: vehicleData.prices.miscellaneous.windowTint || 950,
                    modType: "window_tint",
                    value: item.id
                });
                renderMiscSection("tints");
            };
            grid.appendChild(card);
        });

        container.appendChild(grid);
    } else if (tabId === "plates") {
        focusCameraAuto("plate");
        const list = vehicleData.plates.list || [];
        const grid = document.createElement("div");
        grid.className = "parts-grid-industrial";

        list.forEach(item => {
            const isInstalled = vehicleData.plates.current === item.id;
            const isCart = isItemInCart("plate_index", item.id);

            const card = document.createElement("div");
            card.className = `industrial-card ${isInstalled ? "installed" : ""} ${isCart ? "selected" : ""}`;
            card.innerHTML = `
                <div class="card-headline-row">
                    <span class="part-name-text">${item.name}</span>
                    <span class="flat-badge ${isInstalled ? "badge-installed" : isCart ? "badge-cart" : "badge-level"}">${isInstalled ? "TAKILI" : isCart ? "SEPETTE" : "PLAKA"}</span>
                </div>
                <div class="card-footer-row">
                    <span class="part-price-tag">${formatPrice(vehicleData.prices.miscellaneous.plateIndex || 750)}</span>
                    <div class="action-icon-box"><i class="fa-solid fa-id-card"></i></div>
                </div>
            `;
            card.onclick = () => {
                sendNui("previewMod", { modType: "plate_index", value: item.id });
                toggleCartItem("plate_index", item.id, {
                    title: `Plaka Stili: ${item.name}`,
                    price: vehicleData.prices.miscellaneous.plateIndex || 750,
                    modType: "plate_index",
                    value: item.id
                });
                renderMiscSection("plates");
            };
            grid.appendChild(card);
        });

        container.appendChild(grid);
    } else if (tabId === "horns") {
        const list = vehicleData.horns.list || [];
        const grid = document.createElement("div");
        grid.className = "parts-grid-industrial";

        list.forEach(item => {
            const isInstalled = vehicleData.horns.current === item.id;
            const isCart = isItemInCart("horn", item.id);

            const card = document.createElement("div");
            card.className = `industrial-card ${isInstalled ? "installed" : ""} ${isCart ? "selected" : ""}`;
            card.innerHTML = `
                <div class="card-headline-row">
                    <span class="part-name-text">${item.name}</span>
                    <span class="flat-badge ${isInstalled ? "badge-installed" : isCart ? "badge-cart" : "badge-level"}">${isInstalled ? "TAKILI" : isCart ? "SEPETTE" : "KORNA"}</span>
                </div>
                <div class="card-footer-row">
                    <span class="part-price-tag">${formatPrice(vehicleData.prices.miscellaneous.horns || 600)}</span>
                    <div class="action-icon-box"><i class="fa-solid fa-bullhorn"></i></div>
                </div>
            `;
            card.onclick = () => {
                sendNui("previewMod", { modType: "horn", value: item.id });
                toggleCartItem("horn", item.id, {
                    title: `Korna: ${item.name}`,
                    price: vehicleData.prices.miscellaneous.horns || 600,
                    modType: "horn",
                    value: item.id
                });
                renderMiscSection("horns");
            };
            grid.appendChild(card);
        });

        container.appendChild(grid);
    }
}

// 7. Extras & Livery
function renderExtrasAndLivery(tabId) {
    const container = document.getElementById("content-container");
    container.innerHTML = "";

    if (tabId === "extras_list") {
        focusCameraAuto("default");
        const extras = vehicleData.extras || [];
        if (extras.length === 0) {
            container.innerHTML = `<div style="padding: 30px; text-align: center; color: var(--text-dim); font-size: 13px;">Bu araç için ekstra parça bulunmuyor.</div>`;
            return;
        }

        const panel = document.createElement("div");
        panel.className = "stance-workbench-box";

        extras.forEach(extra => {
            const card = document.createElement("div");
            card.className = "switch-control-card";
            card.innerHTML = `
                <div class="switch-details">
                    <span class="switch-main-label">${extra.name}</span>
                    <span class="switch-price-label">${formatPrice(extra.price)}</span>
                </div>
                <label class="matte-switch">
                    <input type="checkbox" id="extra-toggle-${extra.id}" ${extra.enabled ? "checked" : ""}>
                    <span class="switch-slider"></span>
                </label>
            `;
            panel.appendChild(card);
        });

        container.appendChild(panel);

        extras.forEach(extra => {
            const el = document.getElementById(`extra-toggle-${extra.id}`);
            el.onchange = () => {
                sendNui("previewMod", {
                    modType: "extra",
                    value: el.checked ? 1 : 0,
                    extraData: { id: extra.id }
                });
                toggleCartItem("extra", extra.id, {
                    title: `${extra.name} (${el.checked ? "Aktif" : "Pasif"})`,
                    price: extra.price,
                    modType: "extra",
                    value: el.checked ? 1 : 0,
                    extraData: { id: extra.id }
                });
            };
        });
    } else if (tabId === "livery") {
        renderGenericModSubcategory("48");
    }
}

// 8. Service & Maintenance
function renderServiceSection() {
    const container = document.getElementById("content-container");
    container.innerHTML = "";

    focusCameraAuto("default");

    const missingHealth = (1000 - vehicleData.vehicle.stats.engine) + (1000 - vehicleData.vehicle.stats.body);
    const repairCost = Math.max(250, Math.min(2500, Math.floor(missingHealth * 2.5)));
    const washCost = 150;

    const panel = document.createElement("div");
    panel.className = "parts-grid-industrial";
    panel.style.gridTemplateColumns = "repeat(auto-fill, minmax(280px, 1fr))";

    panel.innerHTML = `
        <div class="industrial-card" id="service-repair-card" style="padding: 16px;">
            <div class="card-headline-row">
                <span class="part-name-text"><i class="fa-solid fa-wrench" style="color: var(--accent-orange); margin-right: 6px;"></i> Komple Araç Onarımı</span>
                <span class="flat-badge badge-level">SERVİS</span>
            </div>
            <p style="font-size: 11px; color: var(--text-muted); line-height: 1.5; margin: 8px 0;">
                Motor, şasi, süspansiyon, camlar ve kaporta hasarlarını sıfırlar ve fabrikasyon haline getirir.
            </p>
            <div class="card-footer-row">
                <span class="part-price-tag">${formatPrice(repairCost)}</span>
                <button class="flat-btn btn-primary" style="padding: 5px 12px; font-size: 11px;">Hemen Onar</button>
            </div>
        </div>

        <div class="industrial-card" id="service-wash-card" style="padding: 16px;">
            <div class="card-headline-row">
                <span class="part-name-text"><i class="fa-solid fa-soap" style="color: #38bdf8; margin-right: 6px;"></i> Detaylı Yıkama & Cila</span>
                <span class="flat-badge badge-level">YIKAMA</span>
            </div>
            <p style="font-size: 11px; color: var(--text-muted); line-height: 1.5; margin: 8px 0;">
                Araç gövdesindeki tüm çamur ve kirleri temizler, parlak seramik kaplama uygular.
            </p>
            <div class="card-footer-row">
                <span class="part-price-tag">${formatPrice(washCost)}</span>
                <button class="flat-btn btn-secondary" style="padding: 5px 12px; font-size: 11px;">Hemen Yıka</button>
            </div>
        </div>
    `;

    container.appendChild(panel);

    document.getElementById("service-repair-card").onclick = () => {
        sendNui("repairVehicle").then(res => {
            if (res.success && res.data) {
                initUI(res.data, null, currencySymbol, currencyPosition);
                renderServiceSection();
            }
        });
    };

    document.getElementById("service-wash-card").onclick = () => {
        sendNui("cleanVehicle").then(res => {
            if (res.success && res.data) {
                initUI(res.data, null, currencySymbol, currencyPosition);
                renderServiceSection();
            }
        });
    };
}

// ============================================================================
// CART MANAGEMENT
// ============================================================================
function isItemInCart(modKey, subId) {
    const key = `${modKey}_${subId}`;
    return cart[key] !== undefined;
}

function toggleCartItem(modKey, subId, itemData) {
    const key = `${modKey}_${subId}`;
    if (cart[key]) {
        delete cart[key];
    } else {
        Object.keys(cart).forEach(k => {
            if (k.startsWith(`${modKey}_`)) {
                delete cart[k];
            }
        });
        cart[key] = itemData;
    }
    updateCartDisplay();
}

function updateCartDisplay() {
    const keys = Object.keys(cart);
    const count = keys.length;
    let totalPrice = 0;

    keys.forEach(k => {
        totalPrice += cart[k].price || 0;
    });

    document.getElementById("cart-count").textContent = count;
    document.getElementById("cart-items-text").textContent = `${count} parça seçildi`;
    document.getElementById("total-price-display").textContent = formatPrice(totalPrice);
    document.getElementById("modal-total-price").textContent = formatPrice(totalPrice);

    const list = document.getElementById("cart-modal-items");
    list.innerHTML = "";

    if (count === 0) {
        list.innerHTML = `<div style="padding: 20px 0; text-align: center; color: var(--text-dim); font-size: 12px;">Sepetinizde henüz modifiye parçası yok.</div>`;
    } else {
        keys.forEach(k => {
            const item = cart[k];
            const div = document.createElement("div");
            div.className = "cart-item-row";
            div.innerHTML = `
                <span class="item-name-text">${item.title}</span>
                <div class="item-right-cell">
                    <span class="item-price-text">${formatPrice(item.price)}</span>
                    <button class="item-delete-btn" title="Kaldır"><i class="fa-solid fa-trash"></i></button>
                </div>
            `;
            div.querySelector(".item-delete-btn").onclick = () => {
                delete cart[k];
                updateCartDisplay();
                switchCategory(currentCategory);
            };
            list.appendChild(div);
        });
    }
}

// ============================================================================
// CAMERA
// ============================================================================
function focusCameraAuto(preset) {
    if (preset === activeCameraPreset) return;
    activeCameraPreset = preset;
    sendNui("focusCamera", { preset: preset });

    document.querySelectorAll(".dock-tab-btn[data-cam]").forEach(btn => {
        btn.classList.toggle("active", btn.dataset.cam === preset);
    });
}

// ============================================================================
// EVENT LISTENERS
// ============================================================================
window.addEventListener("message", (event) => {
    const data = event.data;
    if (data.action === "open") {
        document.getElementById("mechanic-app").classList.remove("hidden");
        initUI(data.data, data.shopName, data.currency, data.currencyPos);
    } else if (data.action === "close") {
        document.getElementById("mechanic-app").classList.add("hidden");
    }
});

// Category Click
document.querySelectorAll(".category-card").forEach(btn => {
    btn.onclick = () => {
        switchCategory(btn.dataset.category);
    };
});

// Camera Dock Buttons
document.querySelectorAll(".dock-tab-btn[data-cam]").forEach(btn => {
    btn.onclick = () => {
        focusCameraAuto(btn.dataset.cam);
    };
});

// Door Dock Buttons
document.querySelectorAll(".door-btn").forEach(btn => {
    btn.onclick = () => {
        sendNui("toggleDoor", { doorIndex: btn.dataset.door });
    };
});

// Cart Modal Open/Close
document.getElementById("cart-summary-btn").onclick = () => {
    document.getElementById("cart-modal").classList.remove("hidden");
};

document.getElementById("cart-modal-close").onclick = () => {
    document.getElementById("cart-modal").classList.add("hidden");
};

document.getElementById("btn-clear-cart").onclick = () => {
    cart = {};
    updateCartDisplay();
    switchCategory(currentCategory);
};

// Checkout Cash
document.getElementById("btn-pay-cash").onclick = () => {
    const keys = Object.keys(cart);
    let totalPrice = 0;
    keys.forEach(k => { totalPrice += cart[k].price || 0; });

    sendNui("checkoutCart", {
        cart: cart,
        totalPrice: totalPrice,
        paymentMethod: "cash"
    }).then(res => {
        if (res.success) {
            cart = {};
            updateCartDisplay();
            sendNui("closeMenu", { restore: false });
        }
    });
};

// Checkout Bank
document.getElementById("btn-pay-bank").onclick = () => {
    const keys = Object.keys(cart);
    let totalPrice = 0;
    keys.forEach(k => { totalPrice += cart[k].price || 0; });

    sendNui("checkoutCart", {
        cart: cart,
        totalPrice: totalPrice,
        paymentMethod: "bank"
    }).then(res => {
        if (res.success) {
            cart = {};
            updateCartDisplay();
            sendNui("closeMenu", { restore: false });
        }
    });
};

// Cancel & Close
document.getElementById("btn-cancel").onclick = () => {
    sendNui("closeMenu", { restore: true });
};

// Keyboard ESC
window.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
        const modal = document.getElementById("cart-modal");
        if (!modal.classList.contains("hidden")) {
            modal.classList.add("hidden");
        } else {
            sendNui("closeMenu", { restore: true });
        }
    }
});

// Mouse Drag Orbit
window.addEventListener("mousedown", (e) => {
    if (e.target.closest(".sidebar-workbench") || e.target.closest(".workbench-main-panel") || e.target.closest(".top-header-strip") || e.target.closest(".bottom-checkout-footer") || e.target.closest(".center-dock-strip") || e.target.closest(".cart-modal-container")) {
        return;
    }
    isMouseDown = true;
    startMouseX = e.clientX;
    startMouseY = e.clientY;
});

window.addEventListener("mousemove", (e) => {
    if (!isMouseDown) return;
    const deltaX = e.clientX - startMouseX;
    const deltaY = e.clientY - startMouseY;
    startMouseX = e.clientX;
    startMouseY = e.clientY;

    sendNui("rotateCamera", { deltaX: deltaX, deltaY: deltaY });
});

window.addEventListener("mouseup", () => {
    isMouseDown = false;
});

window.addEventListener("wheel", (e) => {
    sendNui("rotateCamera", { deltaX: 0, deltaY: 0, zoom: Math.sign(e.deltaY) });
});
