document.addEventListener("DOMContentLoaded", function () {
  mapboxgl.accessToken = mapboxToken;
  
  const map = new mapboxgl.Map({
    container: "map",
    style: "mapbox://styles/mapbox/streets-v11",
    center: [-95, 40],
    zoom: 2.5
  });
  
  map.addControl(new mapboxgl.NavigationControl());
  
  let hoverPopup = new mapboxgl.Popup({ closeButton: false, closeOnClick: false });
  let hoveredFeatureId = null;

  // Add counties layer
  Shiny.addCustomMessageHandler("updateCounties", function (geojsonData) {
    console.log("Received GeoJSON data:", geojsonData);
    
    if (map.getSource("counties")) {
      map.getSource("counties").setData(geojsonData);
    } else {
      map.addSource("counties", {
        type: "geojson",
        data: geojsonData
      });
      map.addLayer({
        id: "counties-layer",
        type: "fill",
        source: "counties",
        paint: {
          "fill-color": [
            "step",
            ["get", "population"],
            "#fff5f0", 10000,
            "#fcbba1", 30000,
            "#fb6a4a", 50000,
            "#cb181d"
          ],
          "fill-opacity": [
            "case",
            ["boolean", ["feature-state", "hover"], false],
            1,
            0.6
          ]
        }
      });
    }
    
    map.on("mousemove", "counties-layer", function (e) {
      if (e.features.length > 0) {
        if (hoveredFeatureId !== null) {
          map.setFeatureState({ source: "counties", id: hoveredFeatureId }, { hover: false });
        }
        hoveredFeatureId = e.features[0].id;
        map.setFeatureState({ source: "counties", id: hoveredFeatureId }, { hover: true });

        const properties = e.features[0].properties;
        hoverPopup
          .setLngLat(e.lngLat)
          .setHTML(`<strong>County:</strong> ${properties.county_name}<br><strong>Population:</strong> ${properties.population}`)
          .addTo(map);
      }
    });

    map.on("mouseleave", "counties-layer", function () {
      if (hoveredFeatureId !== null) {
        map.setFeatureState({ source: "counties", id: hoveredFeatureId }, { hover: false });
      }
      hoveredFeatureId = null;
      hoverPopup.remove();
    });
  });

  // Handle search update
  Shiny.addCustomMessageHandler("updateSearch", function (coords) {
    new mapboxgl.Popup()
      .setLngLat([coords.lng, coords.lat])
      .setHTML(coords.popup)
      .addTo(map);
    map.flyTo({ center: [coords.lng, coords.lat], zoom: 8 });
  });

  // Clear search
  Shiny.addCustomMessageHandler("clearSearch", function () {
    map.flyTo({ center: [-95, 40], zoom: 2.5 });
  });
});
