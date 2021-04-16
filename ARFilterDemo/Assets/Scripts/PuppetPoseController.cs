using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

[RequireComponent(typeof(BlendShapeVisualizer))]
public class PuppetPoseController : MonoBehaviour
{
    ARSessionOrigin sessionOrigin;

    [SerializeField]
    private GameObject faceControlledObject;
    [SerializeField]
    private BlendShapeVisualizer blendShapeVisualizer;

    private float puppetToCameraZ;
    private ARFace face;

    public ARFace Face { set { face = value; } }

    public BlendShapeVisualizer BlendShape { get { return blendShapeVisualizer; } }

    // Start is called before the first frame update
    void Start()
    {
        sessionOrigin = FindObjectOfType<ARSessionOrigin>();

        puppetToCameraZ = Mathf.Abs(faceControlledObject.transform.position.z - Camera.main.transform.position.z);
    }

    private void OnEnable()
    {
        Application.onBeforeRender += OnBeforeRender;
    }

    private void OnDisable()
    {
        Application.onBeforeRender -= OnBeforeRender;
    }

    void OnBeforeRender()
    {
        if(face == null)
        {
            return;
        }
        
        if (face.trackingState == TrackingState.Tracking)
        {
            ControlPosition();
            ControlRotation();
        }
    }

    //Control Position
    //Important: We need to get face local position in the AR camera's space
    private void ControlPosition()
    {
        Vector3 offset = sessionOrigin.camera.transform.InverseTransformPoint(face.transform.position);

        float ratio = Mathf.Abs(puppetToCameraZ / Mathf.Max(0.000001f, (offset.z)));
        Vector3 puppetPosOffset = new Vector3(offset.x * ratio, offset.y * ratio, puppetToCameraZ);
        Vector3 targetPos = Camera.main.transform.position + puppetPosOffset;
        targetPos = LimitPosition(targetPos);
        faceControlledObject.transform.position = targetPos;
    }

    //Control Rotation
    //Important: We need to get face local rotation in the AR camera's space
    private void ControlRotation()
    {
        Quaternion targetRotation = Quaternion.Inverse(sessionOrigin.camera.transform.rotation) * face.transform.rotation;

        faceControlledObject.transform.rotation = targetRotation;
    }

    private Vector3 LimitPosition(Vector3 pos)
    {
        if (pos.x > 1)
        {
            pos.x = 1;
        }
        else if (pos.x < -1)
        {
            pos.x = -1;
        }

        if (pos.y > 3)
        {
            pos.y = 3;
        }
        else if (pos.y < 0.4)
        {
            pos.y = 0.4f;
        }

        return pos;
    }

    private Quaternion LimitRotation(Quaternion rotation)
    {
        Vector3 rotationAngle = rotation.eulerAngles;
        Quaternion newRotation = rotation;

        if (rotationAngle.x > 60)
        {
            newRotation.eulerAngles = new Vector3(60, newRotation.y, newRotation.z);
        }
        else if (rotationAngle.x < -60)
        {
            newRotation.eulerAngles = new Vector3(-60, newRotation.y, newRotation.z);
        }

        if (rotationAngle.y > 60)
        {
            newRotation.eulerAngles = new Vector3(newRotation.x, 60, newRotation.z);
        }
        else if (rotationAngle.y < -60)
        {
            newRotation.eulerAngles = new Vector3(newRotation.x, -60, newRotation.z);
        }

        if(rotationAngle.z > 35)
        {
            newRotation.eulerAngles = new Vector3(newRotation.x, newRotation.y, 30);
        }
        else if(rotationAngle.z < -35)
        {
            newRotation.eulerAngles = new Vector3(newRotation.x, newRotation.y, -30);
        }

        return newRotation;
    }
}
