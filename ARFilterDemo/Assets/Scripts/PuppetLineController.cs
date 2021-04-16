using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PuppetLineController : MonoBehaviour
{
    public HingeJoint Joint;
    public float Speed;
    public MeshRenderer FrameNobe;

    private Joystick joystick;

    private bool isActive;

    public bool IsActive { set { isActive = value; } }

    private void Start()
    {
        joystick = FindObjectOfType<Joystick>();
    }

    private void Update()
    {
        if (isActive)
        {
            if(joystick.Vertical > 0.1)
            {
                Debug.Log("Up");
                Vector3 anchor = Joint.connectedAnchor;
                Joint.connectedAnchor = new Vector3(anchor.x, anchor.y + Time.deltaTime * Speed, anchor.z);
                if(Joint.connectedAnchor.y > -7)
                {
                    Joint.connectedAnchor = new Vector3(anchor.x, -7f, anchor.z);
                }
                else
                {
                    Quaternion nobeRotation = new Quaternion();
                    Vector3 angle = FrameNobe.transform.parent.rotation.eulerAngles;

                    angle.z -= Time.deltaTime * Speed * 50;
                    nobeRotation.eulerAngles = angle;

                    FrameNobe.transform.parent.rotation = nobeRotation;
                }
                
            }
            else if(joystick.Vertical < -0.1)
            {
                Debug.Log("Down");
                Vector3 anchor = Joint.connectedAnchor;
                Joint.connectedAnchor = new Vector3(anchor.x, anchor.y - Time.deltaTime * Speed, anchor.z);
                if (Joint.connectedAnchor.y < -10)
                {
                    Joint.connectedAnchor = new Vector3(anchor.x, -10f, anchor.z);
                }
                else
                {
                    Quaternion nobeRotation = new Quaternion();
                    Vector3 angle = FrameNobe.transform.parent.rotation.eulerAngles;

                    angle.z += Time.deltaTime * Speed * 50;
                    nobeRotation.eulerAngles = angle;

                    FrameNobe.transform.parent.rotation = nobeRotation;
                }
            }
        }
    }
}
