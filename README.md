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

'''swift
processBeacon(items[row], distance: 0.08, frequency: 20, action: provideInfo)
'''

being the method definition the following:

'''swift
func processBeacon(_ beacon: Item, distance: Double, frequency: Int, action: (_ beacon: Item) -> ())
'''

#### Audio Feedback

#### Visual Feedback
