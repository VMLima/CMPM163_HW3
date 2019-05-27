using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MovementUnderwater : MonoBehaviour {

    public float speed;
    public float mouseSpeed;

    [Header("Headbob Variables")]
    [Tooltip("Variable to change how fast the camera will bob")]
    public float bobbingSpeed;
    [Tooltip("Variable to change how high the camera will bob")]
    public float bobbingAmount;
    [Tooltip("Variable changes the center of the bob (effects how tall the character feels)")]
    public float midpoint;

    [Space(5)]
    public Camera cam;

    private Vector3 movement;
    private Rigidbody rig;

    private float InputY;
    private float InputX;
    private float MouseY;
    private float MouseX;

    private float timer = 0.0f;

    [HideInInspector] public float temp;


    void Start() {
        rig = GetComponent<Rigidbody>();
        rig.maxAngularVelocity = mouseSpeed;
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
        temp = speed;
    }

    void FixedUpdate() {

        InputX = Input.GetAxisRaw("Horizontal");
        InputY = Input.GetAxisRaw("Vertical");

        movement = (InputX * transform.right + InputY * transform.forward).normalized * speed;

        if (Input.GetKey(KeyCode.Space)) {
            movement.y += speed;
        } else if (Input.GetKey(KeyCode.C)) {
            movement.y -= speed;
        }

        transform.position += movement * Time.deltaTime;

        //Handles mouse rotation
        MouseX += Input.GetAxis("Mouse X") * mouseSpeed;
        MouseY += Input.GetAxis("Mouse Y") * mouseSpeed;

        transform.eulerAngles = new Vector3(Mathf.Clamp(-MouseY, -90, 90), MouseX, 0);
        cam.transform.eulerAngles = new Vector3(Mathf.Clamp(-MouseY, -90, 90), MouseX, 0);

        if (Input.GetKey(KeyCode.Escape)) {
            Application.Quit();
        }

        // Handles headbob
        float waveslice = 0.0f;

        if (Mathf.Abs(InputX) == 0 && Mathf.Abs(InputY) == 0) {
            waveslice = Mathf.Sin(timer);
            timer += bobbingSpeed;
            if (timer > Mathf.PI * 2) {
                timer -= (Mathf.PI * 2);
            }
        } else {
            timer = 0.0f;
        }

        //if (waveslice != 0) {
        //    cam.transform.localPosition = new Vector3(0, midpoint, 0);
        //} else {
            
            float translateChange = waveslice * bobbingAmount;
            //float totalAxes = Mathf.Abs(InputX) + Mathf.Abs(InputY);
            //totalAxes = Mathf.Clamp(totalAxes, 0.0f, 1.0f);
            //translateChange *= totalAxes;
            cam.transform.localPosition = new Vector3(0, midpoint + translateChange, 0);
        //}
    }

    //void OnTriggerEnter(Collider other) {
    //    if (other.CompareTag("Ground")) {
    //        isGrounded = true;
    //    }
    //}
}
