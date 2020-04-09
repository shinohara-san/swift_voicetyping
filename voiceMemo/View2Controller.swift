import UIKit

class View2Controller: UIViewController {


    @IBOutlet weak var textField: UITextView!
    
    var givenData : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.text = givenData
    }
    


}
