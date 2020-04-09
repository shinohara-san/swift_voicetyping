import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var array = [String]()
    let userDefaults = UserDefaults.standard
    
    var chosenItem : String = ""
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let textCell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        textCell.textLabel?.text = array[indexPath.row]
        return textCell
    }
    

  var isRecording = false
  var w: CGFloat = 0
  var h: CGFloat = 0
  let d: CGFloat = 50
  let l: CGFloat = 28

  let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-us"))!
  var audioEngine: AVAudioEngine!
  var recognitionReq: SFSpeechAudioBufferRecognitionRequest?
  var recognitionTask: SFSpeechRecognitionTask?
  
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var baseView: UIView!
  @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if userDefaults.object(forKey: "messages") != nil{
        array = userDefaults.array(forKey: "messages") as! [String]
//        tableView.reloadData()
    }
    
//    キーボード非表示
    self.view.endEditing(true)
    tableView.delegate = self
    tableView.dataSource = self
    
    audioEngine = AVAudioEngine()
    textView.text = ""
    
    
  }
//　　セル削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            array.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
        }
    }
    
  override func viewDidAppear(_ animated: Bool) {
    w = baseView.frame.size.width
    h = baseView.frame.size.height

    initRoundCorners()
    showStartButton()

    SFSpeechRecognizer.requestAuthorization { (authStatus) in
      DispatchQueue.main.async {
        if authStatus != SFSpeechRecognizerAuthorizationStatus.authorized {
          self.recordButton.isEnabled = false
          self.recordButton.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        }
      }
    }
  }
  @IBAction func saveButtonTapped(_ sender: Any) {
    if let unwrappedText = textView.text {
        array.append(unwrappedText)
        userDefaults.set(array, forKey: "messages")
        textView.text = ""
        if userDefaults.object(forKey: "messages") != nil{
            array = userDefaults.array(forKey: "messages") as! [String]
            tableView.reloadData()
        }
    }
  }
  
  func stopLiveTranscription() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionReq?.endAudio()
  }
  
  func startLiveTranscription() throws {
    // もし前回の音声認識タスクが実行中ならキャンセル
    if let recognitionTask = self.recognitionTask {
      recognitionTask.cancel()
      self.recognitionTask = nil
    }
    textView.text = ""

    // 音声認識リクエストの作成
    recognitionReq = SFSpeechAudioBufferRecognitionRequest()
    guard let recognitionReq = recognitionReq else {
      return
    }
    recognitionReq.shouldReportPartialResults = true

    // オーディオセッションの設定
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    let inputNode = audioEngine.inputNode

    // マイク入力の設定
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { (buffer, time) in
      recognitionReq.append(buffer)
    }
    audioEngine.prepare()
    try audioEngine.start()

    recognitionTask = recognizer.recognitionTask(with: recognitionReq, resultHandler: { (result, error) in
      if let error = error {
        print("\(error)")
      } else {
        DispatchQueue.main.async {
            self.textView.text = (result?.bestTranscription.formattedString)!
        }
      }
    })
  }

    
//     override func prepare(for segue: "goToNextPage", sender: Any?) {
//
//           // ②Segueの識別子確認
//           if segue.identifier == "goToNextPage" {
//
//               // ③遷移先ViewCntrollerの取得
//               let nextView = segue.destination as! View2Controller
//
//               // ④値の設定
//            nextView.label = cell[indexPath.row].text!
//           }
//       }
    
  @IBAction func recordButtonTapped(_ sender: Any) {
    if isRecording {
      UIView.animate(withDuration: 0.2) {
        self.showStartButton()
      }
      stopLiveTranscription()
    } else {
      UIView.animate(withDuration: 0.2) {
        self.showStopButton()
      }
      try! startLiveTranscription()
    }
    isRecording = !isRecording
  }

  func initRoundCorners(){
    recordButton.layer.masksToBounds = true

    baseView.layer.masksToBounds = true
    baseView.layer.cornerRadius = 10
    baseView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

  }
  
  func showStartButton() {
    recordButton.frame = CGRect(x:(w-d)/2,y:(h-d)/2,width:d,height:d)
    recordButton.layer.cornerRadius = d/2
  }
  
  func showStopButton() {
    recordButton.frame = CGRect(x:(w-l)/2,y:(h-l)/2,width:l,height:l)
    recordButton.layer.cornerRadius = 3.0
  }
    
    
    //    セルをタップしたら呼ばれる奴
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        chosenItem = array[indexPath.row]
////        print(chosenItem)
//       }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
////            print("あああああ\(self.chosenItem)")
//            let nextViewController = segue.destination as! View2Controller //遷移先の画面取得
//            nextViewController.givenData = self.chosenItem
//            print(nextViewController.givenData)
//        }
                
//                       }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if ( segue.identifier == "goToNextPage" ) {
            let x = self.tableView.indexPathForSelectedRow
            let y = x?.row
            let post = self.array[y!]
            let p : View2Controller = segue.destination as! View2Controller
            p.givenData = post
        }
    }
    }
