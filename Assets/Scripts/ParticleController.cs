using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleController : MonoBehaviour {

    public ReflectionProbe reflection;
    //public Shader shader;
    //public Shader fishShader;
    public Material bubbleMat;
    public Material fishMat;

    [Range(0, 1)]
    public float bubbleRange = 0.6f;
    private GameObject[] bubbles;
    private GameObject[] fish;
    private Color col;

    // Start is called before the first frame update
    void Start() {
        bubbles = GameObject.FindGameObjectsWithTag("Bubble");
        fish = GameObject.FindGameObjectsWithTag("Fish");
        col = Color.red;
    }

    // Update is called once per frame
    void Update() {
        bubbleMat.SetTexture("_Cube", reflection.texture);

        // Audio Stuff
        int numPartitions = 1;
        float[] aveMag = new float[numPartitions];
        float[] quarterMag = new float[numPartitions];
        float[] quarterTwoMag = new float[numPartitions];
        float partitionIndx = 0;
        int numDisplayedBins = 512 / 2;

        for (int i = 0; i < numDisplayedBins; i++) {
            if (i < numDisplayedBins * (partitionIndx + 1) / numPartitions) {
                aveMag[(int)partitionIndx] += AudioPeer.spectrumData[i] / (512 / numPartitions);
                quarterMag[(int)partitionIndx] += AudioPeer.spectrumData[i] / (512 / numPartitions);
                quarterTwoMag[(int)partitionIndx] += AudioPeer.spectrumData[i] / (512 / numPartitions);
            }
            else {
                partitionIndx++;
                i--;
            }
        }

        for (int i = 0; i < numPartitions; i++) {
            aveMag[i] = (float)0.5 + aveMag[i] * 100;
            quarterMag[i] = (float)0.25 + quarterMag[i] * 50;
            quarterTwoMag[i] = (float)0.75 + quarterTwoMag[i] * 200;
            if (aveMag[i] > 100 || quarterMag[i] > 100 || quarterTwoMag[i] > 100) {
                aveMag[i] = 100;
                quarterMag[i] = 100;
                quarterTwoMag[i] = 100;
            }
        }

        float mag = aveMag[0];
        float mag2 = quarterMag[0];
        float mag3 = quarterTwoMag[0];

        //Debug.Log(mag + " " + mag2 + " " + mag3);
        // if mag is greater than some threshold
        // emit particle using emit function
        if (mag > bubbleRange) {
            bubbles[Random.Range(0, bubbles.Length)].GetComponent<ParticleSystem>().Emit(1);
        }

        col.r += mag - .52f;
        col.g += mag2 - .27f;
        col.b += mag3 - .84f;

        col.r = Mathf.Clamp(col.r, 0, 1);
        col.g = Mathf.Clamp(col.g, 0, 1);
        col.b = Mathf.Clamp(col.b, 0, 1);
        //if (mag > .55) {
        //    col.r = Mathf.SmoothStep(col.r, 1, .1f);
        //} else if (mag2 > .27) {
        //    col.g = Mathf.SmoothStep(col.g, 1, .1f);
        //} else if (mag3 > .82) {
        //    col.b = Mathf.SmoothStep(col.b, 1, .1f);
        //} else if (mag <= .55) {
        //    col.r = Mathf.SmoothStep(col.r, 0, .1f);
        //} else if (mag2 <= .27) {
        //    col.g = Mathf.SmoothStep(col.g, 0, .1f);
        //} else if (mag3 <= .82) {
        //    col.b = Mathf.SmoothStep(col.b, 0, .1f);
        //}
        //Debug.Log(col);
        fishMat.SetColor("_FishColor", col);
    }
}
