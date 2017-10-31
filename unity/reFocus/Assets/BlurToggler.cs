using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityStandardAssets.ImageEffects;

public class BlurToggler : MonoBehaviour {

	public Blur blur;
	public string serverURL;
	public float checkServerInterval; // in seconds
	public WWW serverResponse;

	// Use this for initialization
	void Start () {
		// Disable blur
		blur.enabled = false;

		// Start checking server periodically
		StartCoroutine ("CheckServer");
	}
	
	// Update is called once per frame
	void Update () {
		// Activate/deactivate blur
		if (serverResponse != null && serverResponse.isDone) {
			// Check for errors
			if (!string.IsNullOrEmpty(serverResponse.error)) {
				Debug.Log (serverResponse.error);
			}

			// Check text and change blur accordingly
			Debug.Log (serverResponse.text);
			if (serverResponse.text == "true") {
				blur.enabled = true;
			}
			else {
				blur.enabled = false;
			}
		}
	}

	// Check the server every x seconds
	IEnumerator CheckServer() {
		while (true) {
			yield return new WaitForSeconds (checkServerInterval);

			// Do the actual checking
			Debug.Log("Checking");
			if (serverResponse == null || serverResponse.isDone) {
				serverResponse = new WWW (serverURL);
			}

		}
	}
}
