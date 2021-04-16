using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(LineRenderer))]
public class RopeRenderer : MonoBehaviour
{
    public Transform Target;
    LineRenderer line;
    // Start is called before the first frame update
    void Start()
    {
        line = GetComponent<LineRenderer>();
        line.positionCount = 2;
        line.startWidth = 0.014f;
        line.endWidth = 0.014f;
    }

    // Update is called once per frame
    void Update()
    {
        Vector3[] pos = new Vector3[2];

        pos[0] = transform.position;
        pos[1] = Target.position;

        line.SetPositions(pos);
    }
}
