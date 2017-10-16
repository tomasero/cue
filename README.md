# Cue

    Exploring contextual multimodal cues as memory aids

### Objective

We plan to explore the potential for proximity-triggered contextual audio and visual cues to aid with recognition and recall memory (with an emphasis on recognition) in early stage Alzheimer’s patients. In particular, we’ll be using proximity beacons to determine when the user is close to another person such as a loved one; the beacons will then trigger cues in the form of 

1. audio conveying contextual information such as name, relationship, time/place/details of last interaction, 
2. images and video (using AR) showing previous interactions along with text displaying contextual information, and 
3. music in the form of specific songs associated with specific individuals. 

### Research Questions

We’re interested in tackling the following questions:

- Which modalities of cues are the most effective in improving recognition in early stage Alzheimer’s patients? 
- What advantages and challenges are afforded by each of the different modalities?

### Prior Research and Systems

On the musical front, `TODO`
- The Use of Music to Aid Memory of Alzheimer's Patients https://academic.oup.com/jmt/article-abstract/28/2/101/906612
  - "It would appear that patients diagnosed with probable Alzheimer's disease can be stimulated to responsive participation with the use of long-familiar songs"
- Exploration of verbal and non-verbal semantic knowledge and autobiographical memories starting from popular songs in Alzheimer's disease https://www.cambridge.org/core/journals/international-psychogeriatrics/article/exploration-of-verbal-and-non-verbal-semantic-knowledge-and-autobiographical-memories-starting-from-popular-songs-in-alzheimers-disease/1EF1DF2B6E2C43060375C27760BD4650
  - "Our findings demonstrate that popular songs can be excellent stimuli for reminiscence, such as the ability to produce an autobiographical memory related to a song. Thus, we confirm that musical semantic knowledge associated with a song may be relatively preserved in the early stages of AD. This leads to new possibilities for cognitive stimulation."

### System

The system is composed of three subsystems

- Target identification
- Audio feedback
- Visual feedback

#### User Identification

We are using bluetooth beacon technology to idenfity and estimate the distance to the targets (humans or locations) the user is engaging with.

##### Assumptions

- The people interacting with the user will configure their phones as beacons, or will carry a dedicated beacon with themselves
- These people will have previously registered in the user's app

##### iOS Application

We followed Ray Wenderlich's [iBeacon Tutorial with iOS and Swift](https://www.raywenderlich.com/152330/ibeacon-tutorial-ios-swift) to rapidly get a working app that used this technology. There were a bunch of problems in the tutorial that we had to debug by ourselves, especially because it was written for Swift 3 and we were using Swift 4. Once it was working, we adapted the app by including our own logic to trigger audio notifications if a target is at a distance of x meters or less, and at a specified frequency once the target is within the triggering range.

To add new interactions, call processBeacon with the beacon you want to associate the action with, the maximum distance for the trigger range, the frequency you want the action to be repeated once the target is inside the trigger range, and the action you want to be performed. Example:

```swift
processBeacon(items[row], distance: 0.08, frequency: 20, action: provideInfo)
```

being the method definition the following:

```swift
func processBeacon(_ beacon: Item, distance: Double, frequency: Int, action: (_ beacon: Item) -> ())
```

##### Unity Application

We used the [Vuforia](https://vuforia.com/) SDK for Unity to build an AR app that would display images and video in real space when presented with a marker. Our goal was to run this app on the Epson Moverio BT-200 wearable display in order for seamless integration into the patient's everyday life.

The main issues on this front had to do with compatibility issues between Vuforia, Unity, Android, and the Moverio eyewear itself. These are the versions we used:
- Unity <= 5.5
- Vuforia SDK 6.2.10
- Android 4.0.3 (API level 15)
^ Using these same versions will save you a lot of headache!

To run the app, open unity/MementoBook_Unity/Assets/Scenes/TestScene.unity and build the project for your desired platform.


#### Adding a user

#### Audio Feedback
Once the patient enters within a given proximity to a loved one, the patient's beacon will issue verbal audio conveying information about the person's name, gender, and relationship.

Following this brief description, an excerpt of the song associated with the loved one will play back. 

#### Visual Feedback

