using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MovementController : MonoBehaviour {

    public float speed;
    public float mouseSpeed;
    public float jumpSpeed;

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

    private bool isGrounded = true;
    private bool crouched;

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
        if (crouched) {
            speed = temp - 2;
        }
        else {
            speed = temp;
        }

        InputX = Input.GetAxisRaw("Horizontal");
        InputY = Input.GetAxisRaw("Vertical");

        movement = (InputX * transform.right + InputY * transform.forward).normalized * speed;

        transform.position += movement * Time.deltaTime;
        //Debug.Log(rig.velocity.y);
        //movement = new Vector3(movement.x, rig.velocity.y, movement.z);

        //rig.velocity = movement * Time.deltaTime;


        //Handles mouse rotation
        MouseX += Input.GetAxis("Mouse X") * mouseSpeed;
        MouseY += Input.GetAxis("Mouse Y") * mouseSpeed;

        transform.eulerAngles = new Vector3(0, MouseX, 0);
        cam.transform.eulerAngles = new Vector3(Mathf.Clamp(-MouseY, -90, 90), MouseX, 0);

        // Handles jumping
        if (Input.GetKey(KeyCode.Space) && isGrounded) {
            rig.velocity = transform.up * jumpSpeed;
            isGrounded = false;
        }

        if (Input.GetKey(KeyCode.Escape)) {
            Application.Quit();
        }

        // Crouching 
        if (Input.GetKeyDown(KeyCode.LeftControl)) {
            cam.transform.localPosition = new Vector3(0, 0, 0);
            crouched = true;
        } else if (Input.GetKeyUp(KeyCode.LeftControl)) {
            cam.transform.localPosition = new Vector3(0, 0.75f, 0);
            crouched = false;
        }

        // Handles headbob
        float waveslice = 0.0f;

        if (Mathf.Abs(InputX) == 0 && Mathf.Abs(InputY) == 0) {
            timer = 0.0f;
        } else {
            waveslice = Mathf.Sin(timer);
            timer += bobbingSpeed;
            if (timer > Mathf.PI * 2) {
                timer -= (Mathf.PI * 2);
            }
        }

        if (waveslice != 0) {
            float translateChange = waveslice * bobbingAmount;
            float totalAxes = Mathf.Abs(InputX) + Mathf.Abs(InputY);
            totalAxes = Mathf.Clamp(totalAxes, 0.0f, 1.0f);
            translateChange *= totalAxes;
            cam.transform.localPosition = new Vector3(0, midpoint + translateChange, 0);
        } else {
            cam.transform.localPosition = new Vector3(0, midpoint, 0);
        }
    }

    void OnCollisionEnter(Collision collision) {
        if (collision.gameObject.CompareTag("Ground")) {
            isGrounded = true;
        }
    }

    //void OnTriggerEnter(Collider other) {
    //    if (other.CompareTag("Ground")) {
    //        isGrounded = true;
    //    }
    //}
}
