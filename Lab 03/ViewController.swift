//
//  ViewController.swift
//  Lab 03
//
//  Created by Subash Chalise on 2023-11-18.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchLocationInput: UITextField!
    @IBOutlet weak var weatherCondition: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    var lat = ""
    var long = ""
    
    var tempCelsius = ""
    var tempFarenheit = ""
    
    var currentLocation = CLLocationManager()
    
    let weatherIcons: [WeatherCondition] = [
        WeatherCondition(text: "sun.max.fill", code: 1000),
        WeatherCondition(text: "cloud", code: 1003),
        WeatherCondition(text: "cloud.fog", code: 1006),
        WeatherCondition(text: "cloud.snow", code: 1219),
        WeatherCondition(text: "cloud.heavyrain", code: 1195)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        searchLocationInput.delegate = self
        
        currentLocation.delegate = self
        currentLocation.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        currentLocation.requestAlwaysAuthorization()
        currentLocation.requestWhenInUseAuthorization()
        currentLocation.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation :CLLocation = locations[0] as CLLocation
        
        lat = "\(userLocation.coordinate.latitude)"
        long = "\(userLocation.coordinate.longitude)"
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        loadWeather(search: searchLocationInput.text ?? "")
        return true
    }
    
    private func displayWeatherImg(code: Int) {
        let config = UIImage.SymbolConfiguration(paletteColors: [
            .systemBlue, .systemIndigo, .systemMint
        ])
        
        weatherCondition.preferredSymbolConfiguration = config
        
        var imageName = "sun.max.fill"
        
        for item in weatherIcons {
            if item.code == code {
                imageName = item.text
                break
            }
        }
        
        weatherCondition.image = UIImage(systemName: imageName)
    }
    
    @IBAction func targetLocation(_ sender: UIButton) {
        loadWeather(search: "\(lat),\(long)")
    }
    
    @IBAction func searchLocation(_ sender: UIButton) {
        loadWeather(search: searchLocationInput.text)
    }
    
    private  func loadWeather(search: String?) {
        guard let search = search else  {
            return
        }
        
        guard let url = getURL(query: search) else {
            print("Cannot find URL")
            return
        }
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { data, response, error in
            print("Network call complete")
            
            guard error == nil else {
                print("Recieved error")
                return
            }
            
            guard let data = data else {
                print("No data found")
                return
            }
            
            if let weatherResponse = parseJson(data: data) {
                
                DispatchQueue.main.async {
                    self.locationLabel.text = weatherResponse.location.name
                    self.temperatureLabel.text = "\(weatherResponse.current.temp_c)°C"
                    
                    self.tempCelsius = "\(weatherResponse.current.temp_c)"
                    self.tempFarenheit = "\(weatherResponse.current.temp_f)"
                    
                    self.displayWeatherImg(code: weatherResponse.current.condition.code)
                }
            }
        }
        
        dataTask.resume()
    }
    
    @IBAction func switchTemp(_ sender: UISwitch) {
        if sender.isOn {
            temperatureLabel.text = tempFarenheit + "°F"
        } else {
            temperatureLabel.text = tempCelsius + "°C"
        }
        
    }
    
    private func getURL(query: String) -> URL? {
        let baseURL = "https://api.weatherapi.com/v1/"
        let currentEndPoint = "current.json"
        let apiKey = "1aff7bffb21b45c795c193154231811"
        guard let url = "\(baseURL)\(currentEndPoint)?key=\(apiKey)&q=\(query)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: url)
    }
}

private func parseJson(data: Data) -> WeatherResponse? {
    let decoder = JSONDecoder()
    var weather: WeatherResponse?
    do {
        weather = try decoder.decode(WeatherResponse.self , from: data)
    } catch {
        print("Error decoding")
    }
    
    return weather
}


struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}
