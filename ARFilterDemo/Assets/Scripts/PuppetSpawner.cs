using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

[RequireComponent(typeof(ARFace))]
public class PuppetSpawner : MonoBehaviour
{
    [SerializeField]
    private PuppetPoseController PuppetPrefab;

    private ARFace face;
    private PuppetPoseController puppet;
    private Transform SpawnPos;

    private void OnEnable()
    {
        SpawnPos = GameObject.FindWithTag("SpawnPos").transform;

        face = GetComponent<ARFace>();
        face.updated += SpawnPuppet;
    }

    private void OnDisable()
    {
        face.updated -= SpawnPuppet;
    }

    void SpawnPuppet(ARFaceUpdatedEventArgs eventArgs)
    {
        if(face.trackingState == TrackingState.Tracking)
        {
            if(puppet == null)
            {
                PuppetPoseController newPuppet = Instantiate(PuppetPrefab);
                newPuppet.transform.position = SpawnPos.position;
                newPuppet.Face = face;
                newPuppet.BlendShape.Face = face;

                puppet = newPuppet;
            }
        }
    }

    private void OnDestroy()
    {
        Destroy(puppet.gameObject);
    }
}
