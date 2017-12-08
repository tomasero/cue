/*
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import CoreLocation
import AVFoundation
import MediaPlayer

let storedItemsKey = "storedItems"

class ItemsViewController: UIViewController, UIImagePickerControllerDelegate,
  UINavigationControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
	
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var imagePicked: UIImageView!
  // @IBOutlet weak var btnAudioRecord: UIButton!
  
  let locationManager = CLLocationManager()
  var items = [Item]()
  var hasRunFuncTests = false
  var musicMode = false
  var speaking = false
  var playing = false
  var songName = ""
  var currBeacon: Item?
  let synth = AVSpeechSynthesizer()
  
  var recordingSession : AVAudioSession!
  var audioRecorder    :AVAudioRecorder!
  var audioRecorderSettings = [String : Int]()
  var audioPlayer : AVAudioPlayer!
  var audioURLs = [UUID: URL]()
  let audioPlaybackOffset : TimeInterval = 5 // How many seconds before the end of the recording we want to start playback
  var isRecording = false
  var proximityStatuses = [UUID: Bool]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    synth.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.delegate = self
    
    loadItems()
    
    // Audio recording session
    recordingSession = AVAudioSession.sharedInstance()
    do {
      try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
      try recordingSession.setActive(true)
      recordingSession.requestRecordPermission() { [unowned self] allowed in
        DispatchQueue.main.async {
          if allowed {
            print("Allow")
          } else {
            print("Dont Allow")
          }
        }
      }
    } catch {
      print("failed to record!")
    }
    
    // Audio Settings
    audioRecorderSettings = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 12000,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
  }
  
  func loadItems() {
    guard let storedItems = UserDefaults.standard.array(forKey: storedItemsKey) as? [Data] else { return }
    for itemData in storedItems {
      guard let item = NSKeyedUnarchiver.unarchiveObject(with: itemData) as? Item else { continue }
      items.append(item)
      startMonitoringItem(item)
    }
  }
  
  func persistItems() {
    var itemsData = [Data]()
    for item in items {
      let itemData = NSKeyedArchiver.archivedData(withRootObject: item)
      itemsData.append(itemData)
    }
    UserDefaults.standard.set(itemsData, forKey: storedItemsKey)
    UserDefaults.standard.synchronize()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "segueAdd", let viewController = segue.destination as? AddItemViewController {
      viewController.delegate = self
    }
  }
  
  func startMonitoringItem(_ item: Item) {
    let beaconRegion = item.asBeaconRegion()
    locationManager.startMonitoring(for: beaconRegion)
    locationManager.startRangingBeacons(in: beaconRegion)
  }

  func stopMonitoringItem(_ item: Item) {
    let beaconRegion = item.asBeaconRegion()
    locationManager.stopMonitoring(for: beaconRegion)
    locationManager.stopRangingBeacons(in: beaconRegion)
  }
  
}

extension ItemsViewController: AddBeacon {
  func addBeacon(item: Item) {
    items.append(item)
    
    tableView.beginUpdates()
    let newIndexPath = IndexPath(row: items.count - 1, section: 0)
    tableView.insertRows(at: [newIndexPath], with: .automatic)
    tableView.endUpdates()
    
    startMonitoringItem(item)
    
    persistItems()
  }
}

extension ItemsViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    print("Failed monitoring region: \(error.localizedDescription)")
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location manager region: \(error.localizedDescription)")
  }
  
  func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    // (^ This gets called a a consistent interval)
    
    // TESTING functions without beacons
    if (!hasRunFuncTests) {
      print("running func tests")
      if items.count > 0 {
        // Speak
        provideInfo(items[0])
        
        // Play song
        //DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
        //  self.playSongForBeacon(self.items[0])
        //})
        
        // Start recording
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
          self.startRecordingAudioForBeacon(self.items[0])
        })
        
        // Finish recording
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(12), execute: {
          self.finishRecording(success: true)
        })
        
        // Play back recording
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(14), execute: {
          self.startPlayingAudioForBeacon(self.items[0])
        })
      }
      hasRunFuncTests = true
    }

    //Find the same beacons in the table.
    var indexPaths = [IndexPath]()
    for beacon in beacons {
      for row in 0..<items.count {
        // TODO: Determine if item is equal to ranged beacon
        if items[row] == beacon {
          items[row].beacon = beacon
          indexPaths += [IndexPath(row: row, section: 0)]
          processBeacon(items[row], distance: 0.08, frequency: 20, action: provideInfo, taskNumber: 0) // Provide info
          activateMusicMode(items[row])
        }
      }
    }
    
    // Update beacon locations of visible rows.
    if let visibleRows = tableView.indexPathsForVisibleRows {
      let rowsToUpdate = visibleRows.filter { indexPaths.contains($0) }
      for row in rowsToUpdate {
        let cell = tableView.cellForRow(at: row)  as! ItemCell
        cell.refreshLocation()
      }
    }
  }
}

extension ItemsViewController: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    self.speaking = false
    if !musicMode { return }
    print("finished")
    print(currBeacon!.name)
    if let currBeacon = currBeacon {
      print("inside")
      processBeacon(currBeacon, distance: 0.08, frequency: 20, action: playSongForBeacon, taskNumber: 1)
    }
  }
  
  func activateMusicMode(_ beacon: Item) {
    print("activate music mode")
    musicMode = true
    currBeacon = beacon
  }
  
  func speak(_ text: String) {
    speaking = true
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
    synth.speak(utterance)
  }
  
  func provideInfo(_ beacon: Item) {
    print("Provide Info")
    let pronoun = ["Male": "He", "Female": "She"]
    speak("This is \(beacon.name). \(pronoun[beacon.gender] ?? "It") is your \(beacon.relationship).")
  }
  
  
  ///////////////////////////////
  // Perform interactions here //
  ///////////////////////////////
  //func processBeacon(_ beacon: Item, distance: Double, frequency: Int) {
  func processBeacon(_ beacon: Item, distance: Double, frequency: Int, action: (_ beacon: Item) -> (), taskNumber: Int) {
    print("processBeacon")
    print(taskNumber)
    if speaking || playing {
      return
    }
    print("---------")
    if beacon.accuracy < distance {
      print(beacon.name, ": ", beacon.counter)
      if beacon.proximity != .unknown && beacon.counter == taskNumber {
        print("taskNumber: \(taskNumber)")
        action(beacon)
      }
      beacon.counter = (beacon.counter + 1) % frequency
    } else {
      beacon.counter = 0
    }
  }
  
  func playSong(_ songTitle: String, _ duration: Int) {
    print("playing song " + songTitle)
    playing = true
    
    // Find song in media library
    let query = MPMediaQuery.songs()
    let isPresent = MPMediaPropertyPredicate(value: songTitle, forProperty: MPMediaItemPropertyTitle, comparisonType: .equalTo)
    query.addFilterPredicate(isPresent)
    
    let result = query.collections
    if result!.count == 0 {
      print("song " + songTitle + " not found")
      return
    }
    
    // Set up music player
    let controller = MPMusicPlayerController.applicationMusicPlayer()
    let item = result![0]
    
    // Play song
    controller.setQueue(with: item)
    controller.prepareToPlay()
    controller.play()
    
    // Stop song after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration), execute: {
      controller.stop()
    })
  }
  
  func playSongForBeacon(_ beacon: Item) {
    print("playSongForBeacon: name=\(beacon.name), songTitle=\(beacon.songTitle)")
    playSong(beacon.songTitle, 10)
    playing = false
  }
  
  // Audio recording stuff
  
  func startRecordingAudioForBeacon(_ beacon: Item) {
    print("startRecordingAudioForBeacon: name=\(beacon.name)")
    
    if audioRecorder == nil {
      //self.btnAudioRecord.setTitle("Stop", for: UIControlState.normal)
      //self.btnAudioRecord.backgroundColor = UIColor(red: 119.0/255.0, green: 119.0/255.0, blue: 119.0/255.0, alpha: 1.0)
      self.startRecording(beacon.uuid)
    } else {
      // Do nothing
      //self.btnAudioRecord.setTitle("Record", for: UIControlState.normal)
      //self.btnAudioRecord.backgroundColor = UIColor(red: 221.0/255.0, green: 27.0/255.0, blue: 50.0/255.0, alpha: 1.0)
      //self.finishRecording(success: true)
    }
    
    self.isRecording = true
  }
  
  func stopRecordingAudioForBeacon(_ beacon: Item) {
    finishRecording(success: true)
    audioRecorder = nil
    self.isRecording = false
  }
  
  func audioDirectoryURL(_ uuid: UUID) -> NSURL? {
    let uuidString = uuid.uuidString
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentDirectory = urls[0] as NSURL
    let soundURL = documentDirectory.appendingPathComponent("sound_\(uuidString).m4a")
    print(soundURL!)
    return soundURL as NSURL?
  }
  
  func startRecording(_ uuid: UUID) {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      let url = self.audioDirectoryURL(uuid)! as URL
      audioRecorder = try AVAudioRecorder(url: url,
                                          settings: audioRecorderSettings)
      audioRecorder.delegate = self
      audioRecorder.prepareToRecord()
      
      audioURLs[uuid] = url
      print("url = \(url)")
    } catch {
      finishRecording(success: false)
    }
    do {
      try audioSession.setActive(true)
      audioRecorder.record()
    } catch {
    }
  }
  
  func finishRecording(success: Bool) {
    audioRecorder.stop()
    if success {
      print(success)
    } else {
      audioRecorder = nil
      print("Somthing Wrong.")
    }
  }
  
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if !flag {
      finishRecording(success: false)
    }
  }
  
  // Audio playback
  
  func startPlayingAudioForBeacon(_ beacon : Item) {
    if audioRecorder == nil || !audioRecorder.isRecording {
      print("startPlayingAudioForBeacon: name=\(beacon.name)")
      
      //self.audioPlayer = try! AVAudioPlayer(contentsOf: audioRecorder.url)
      //print(audioRecorder.url)
      
      self.audioPlayer = try! AVAudioPlayer(contentsOf: audioURLs[beacon.uuid]!)
      print(audioURLs[beacon.uuid]!)
      
      self.audioPlayer.prepareToPlay()
      self.audioPlayer.delegate = self
      print("old currentTime=\(self.audioPlayer.currentTime)")
      self.audioPlayer.currentTime = max(0 as TimeInterval, self.audioPlayer.duration - audioPlaybackOffset)
      print("new currentTime=\(self.audioPlayer.currentTime)")
      self.audioPlayer.play()
    }
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    print(flag)
  }
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?){
    print(error.debugDescription)
  }
  internal func audioPlayerBeginInterruption(_ player: AVAudioPlayer){
    print(player.debugDescription)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}

// MARK: UITableViewDataSource
extension ItemsViewController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemCell
    cell.item = items[indexPath.row]
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
    if editingStyle == .delete {
      tableView.beginUpdates()
      items.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .automatic)
      tableView.endUpdates()
      
      stopMonitoringItem(items[indexPath.row])
      
      persistItems()
    }
  }
}

// MARK: UITableViewDelegate
extension ItemsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let item = items[indexPath.row]
    let detailMessage = "UUID: \(item.uuid.uuidString)\nMajor: \(item.majorValue)\nMinor: \(item.minorValue)"
    let detailAlert = UIAlertController(title: "Details", message: detailMessage, preferredStyle: .alert)
    detailAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    self.present(detailAlert, animated: true, completion: nil)
  }
}

