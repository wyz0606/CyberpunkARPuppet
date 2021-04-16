using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DistanceManager : MonoBehaviour
{
    public GameObject Target;
    private Vector3 distance;
    // Start is called before the first frame update
    void Start()
    {
        distance = Target.transform.position - transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        transform.position = Target.transform.position - distance;
    }
}
