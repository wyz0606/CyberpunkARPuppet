using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RopeSpawner : MonoBehaviour
{
    public int RopeLength;
    public float SegmentLength;
    public float Width;
    public int Spring;
    public int Damper;
    public GameObject SegmentPrefab;
    public GameObject Joint;

    public List<Rigidbody> segmentList;
    public List<Rigidbody> jointList;

    // Start is called before the first frame update
    void Start()
    {
        segmentList = new List<Rigidbody>();
        jointList = new List<Rigidbody>();

        for(int i = 0; i< RopeLength; i++)
        {
            GameObject segment = Instantiate(SegmentPrefab, transform);
            segment.transform.localScale = new Vector3(Width, SegmentLength, Width);
            segment.transform.localPosition = new Vector3(0, -i * 3f * SegmentLength - SegmentLength, 0);

            Rigidbody rb = segment.GetComponent<Rigidbody>();
            //rb.isKinematic = true;
            //rb.constraints = RigidbodyConstraints.FreezePositionZ | RigidbodyConstraints.FreezeRotationX;
            segmentList.Add(rb);

            if(i == 0)
            {
                rb.isKinematic = true;
            }

            if(i < RopeLength - 1)
            {
                GameObject joint = Instantiate(Joint, transform);
                joint.name = "Joint";
                Rigidbody jRb = joint.GetComponent<Rigidbody>();
                //jRb.isKinematic = true;
                joint.transform.localScale = new Vector3(Width, SegmentLength, Width);
                joint.transform.localPosition = segment.transform.localPosition - new Vector3(0, SegmentLength*1.5f, 0);
                //jRb.constraints = RigidbodyConstraints.FreezePositionZ | RigidbodyConstraints.FreezeRotationX;
                jointList.Add(jRb);
            }
        }

        for (int i = 0; i < jointList.Count; i++)
        {
            JointLimits jL = new JointLimits();
            jL.bounceMinVelocity = 0;
            //jL.max = 1;
            //jL.min = 0;

            JointSpring jS = new JointSpring();
            jS.spring = Spring;
            jS.damper = Damper;

            HingeJoint hingeJoint1 = jointList[i].gameObject.AddComponent<HingeJoint>();
            hingeJoint1.anchor = new Vector3(0,0.5f,0);
            hingeJoint1.useSpring = true;

            hingeJoint1.spring = jS;
            hingeJoint1.useLimits = true;
            hingeJoint1.limits = jL;

            hingeJoint1.connectedBody = segmentList[i];

            HingeJoint hingeJoint2 = jointList[i].gameObject.AddComponent<HingeJoint>();
            hingeJoint2.anchor = new Vector3(0,0.5f,0);
            hingeJoint2.useSpring = true;
            hingeJoint2.spring = jS;
            hingeJoint2.useLimits = true;
            hingeJoint2.limits = jL;

            hingeJoint2.connectedBody = segmentList[i + 1];
        }
    }
}
