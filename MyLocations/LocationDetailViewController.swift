//
//  LocationDetailViewController.swift
//  MyLocations
//
//  Created by Alper on 25/11/16.
//  Copyright © 2016 alper. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
//DateFormatter is a relatively expensive object to create. In other words, it takes quite long to initialize this object. If you do that many times over then it may slow down your app (and drain the phone’s battery faster).
//It is better to create DateFormatter just once and then re-use that same object over and over. The trick is that you won’t create the DateFormatter object until the app actually needs it. This principle is called "lazy loading" and it’s a very important pattern for iOS apps. The work that you don’t do won’t cost any battery power.
//In addition, you’ll only ever create one instance of DateFormatter. The next time you need to use DateFormatter you won’t make a new instance but re-use the existing one.
//To pull this off you’ll use a private global constant. That’s a constant that lives outside of the LocationDetailViewController class (global) but it is only visible inside the LocationDetailsViewController.swift file (private).It means that this constant is private so it cannot be used outside of this Swift file.
//Inside the closure is the code that creates and initializes the new DateFormatter object, and then returns it. This returned value is what gets put into dateFormatter. The knack to making this work is the () at the end. Closures are like functions, and to perform the code inside the closure you call it just like you’d call a function.

//Note: If you leave out the (), Swift thinks you’re assigning the closure itself to dateFormatter – in other words, dateFormatter will contain a block of code, not an actual DateFormatter object. That’s not what you want.
//Instead you want to assign the result of that closure to dateFormatter. To make that happen, you use the () to perform or evaluate the closure – this runs the code inside the closure and returns the DateFormatter object.
//In Swift, globals are always created in a lazy fashion, which means the code that creates and sets up this DateFormatter object isn’t performed until the very first time the dateFormatter global is used in the app.
private let dateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
    
}()

class LocationDetailViewController: UITableViewController{

    
    //MARK: - Globals
    
    var coordinate = CLLocationCoordinate2D(latitude: 0,longitude: 0)
    var placemark : CLPlacemark?
    var categoryName = "No Category"
    var locationDescription = ""
    var date = Date()
    var managedObjectContext : NSManagedObjectContext!
    
    var locationToEdit : Location? {
        didSet{
            
            if let location = locationToEdit {
                categoryName = location.category
                coordinate = CLLocationCoordinate2D(latitude: location.latitude,
                                                    longitude: location.longitude)
                placemark = location.placemark
                locationDescription = location.locationDescription
                date = location.date
            }
        
        }
    }
    
    
    
    //MARK: - Outlets
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    //MARK: - Actions
    @IBAction func done() {
        //dismiss(animated: true, completion: nil)
        let hudView = HudView.hudView(inView: navigationController!.view, animated: true)
        let location : Location
        
        
        if let temp = locationToEdit{
            
            hudView.text = "Updated"
            location = temp
        
        }else{
        
            hudView.text = "Tagged"
            
            //1 - First,you create a new Location instance. Because this is a managed object, you have to use its init(context:) method. You can’t just write Location() because then the managedObjectContext won’t know about the new object.
            location = Location(context: managedObjectContext)
        }
        
    
        //2 - Once you have created new Location instance or use the same Location instance,you can use it like any other object. Here you set its properties to whatever the user entered in the screen.
        location.category = categoryName
        location.date = date
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.locationDescription = descriptionTextView.text
        location.placemark = placemark
        
        
        // 3 - You now have Location object whose properties are all filled in, but if you were to look in the data store at this point you’d still see no objects there. That won’t happen until you save() the context.
        // Info : Saving takes any objects that were added to the context, or any managed objects that had their contents changed, and permanently writes these changes into the data store. That’s why they call the context the “scratchpad”; its changes aren’t persisted until you save them.
        do{
            // any method that can potentially fail must have the try keyword in front of it. And that method call with the try keyword must be inside a do-catch block.
            try managedObjectContext.save()
            
            //tell the app to close the Tag Location screen after 0.6 seconds
            afterDelay(0.6, closure: {
                self.dismiss(animated: true, completion: nil)
            })
        
        }catch{
            fatalCoreDataError(error)
        }
        
        
    }
    @IBAction func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = locationToEdit{
            title = "Edit Location"
        }
        
        descriptionTextView.text = locationDescription
        categoryLabel.text = categoryName
        latitudeLabel.text = String(format: "%.8f",coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark{
            addressLabel.text = string(from: placemark)
        }else{
            addressLabel.text = "No Address Found"
        }
        
        dateLabel.text = format(date: Date())
        
        
        //Speaking of the text view, once you’ve activated it there’s no way to get rid of the keyboard again. And because the keyboard takes up half of the screen that can be a bit annoying.
        //It would be nice if the keyboard disappeared after you tapped anywhere else on the screen.
        let gestureRecognizer = UIGestureRecognizer(target: self, action:#selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            
            controller.selectedCategoryName = categoryName
        }
        
    }
    
    
    // Unwind segue
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue){
    
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    //MARK: - Convenience Methods
    
    func string(from placemark: CLPlacemark) -> String {
        var text = ""
        if let s = placemark.subThoroughfare {
            text += s + " " }
        if let s = placemark.thoroughfare {
            text += s + ", "
        }
        if let s = placemark.locality {
            text += s + ", "
        }
        if let s = placemark.administrativeArea {
            text += s + " " }
        if let s = placemark.postalCode {
            text += s + ", "
        }
        if let s = placemark.country {
            text += s }
        return text }

    func format(date : Date) -> String{
        return dateFormatter.string(from: date)
    }

    func hideKeyboard(_ gestureRecognizer : UIGestureRecognizer){
        
        // the point tapped in tableView
        let point = gestureRecognizer.location(in: tableView)
        //indexPath of tapped point
        let indexPath = tableView.indexPathForRow(at: point)
        
        //if tapped point is description cell, dont hide keyboard
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {
            return
        }
        // Another way : if let indexPath = indexPath, indexPath.section != 0 &&indexPath.row != 0 {return}

        
        //resign first responder status
        descriptionTextView.resignFirstResponder()
        
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 && indexPath.row == 0{
            //descriptionLabel cell
            return 88
        }else if indexPath.section == 2 && indexPath.row == 2 {
            //addressLabel cell
            addressLabel.frame.size = CGSize(
                width: view.bounds.size.width - 115,
                height: 10000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            return addressLabel.frame.size.height + 20
        }else{
            //all other cells
            return 44
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        //the selectible tableView cells are description and addPhoto cells 
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        }else{
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //When the user taps anywhere inside that first cell, the text view should activate, even if the tap wasn’t on the text view itself.
        if indexPath.section == 0 && indexPath.row == 0{
            descriptionTextView.becomeFirstResponder()
        }
    }
}
