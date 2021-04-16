using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEditor;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARKit;

public class BlendShapeVisualizer : MonoBehaviour
{
    [SerializeField]
    private BlendShapeMappings blendShapeMappings;


    [SerializeField]
    private SkinnedMeshRenderer skinnedMeshRenderer;

    [SerializeField]
    private ARKitFaceSubsystem aRKitFaceSubsystem;

    private ARFace face;

    public ARFace Face { set { face = value; } }

    private Dictionary<ARKitBlendShapeLocation, int> faceARkitBlendShapeIndexMap = new Dictionary<ARKitBlendShapeLocation, int>();

    // Start is called before the first frame update
    void Start()
    {

        CreateFeatureBlendMapping();
    }

    void CreateFeatureBlendMapping()
    {
        if (blendShapeMappings.Mappings == null || blendShapeMappings.Mappings.Count == 0)
        {
            Debug.LogError("Mappings must be configured before using BlendShapeVisualizer");
            return;
        }

        if (skinnedMeshRenderer == null || skinnedMeshRenderer.sharedMesh == null)
        {
            return;
        }

        foreach (Mapping mapping in blendShapeMappings.Mappings)
        {
            faceARkitBlendShapeIndexMap[mapping.location] = skinnedMeshRenderer.sharedMesh.GetBlendShapeIndex(mapping.name);
            //Debug.Log(mapping.location + "  |  " + mapping.name + "  |  " + faceARkitBlendShapeIndexMap[mapping.location]);
        }
    }

    private void OnEnable()
    {
        var faceManager = FindObjectOfType<ARFaceManager>();

        if (faceManager != null)
        {
            aRKitFaceSubsystem = (ARKitFaceSubsystem)faceManager.subsystem;
        }

        StartCoroutine(Initialization());
    }

    IEnumerator Initialization()
    {
        yield return new WaitUntil(() => face != null);
        face.updated += OnUpdated;
    }

    private void OnDisable()
    {
        if(face != null)
        {
            face.updated -= OnUpdated;
        }
    }

    void OnUpdated(ARFaceUpdatedEventArgs eventArgs)
    {
        UpdateFaceFeatures();
    }

    void UpdateFaceFeatures()
    {
        
        if (skinnedMeshRenderer == null || !skinnedMeshRenderer.enabled || skinnedMeshRenderer.sharedMesh == null)
        {
            return;
        }

        using (var blendShapes = aRKitFaceSubsystem.GetBlendShapeCoefficients(face.trackableId, Allocator.Temp))
        {
            foreach (var featureCoefficient in blendShapes)
            {
                //Debug.LogFormat("Location: {0}, Coefficient: {1}", featureCoefficient.blendShapeLocation, featureCoefficient.coefficient);
                int mappedBlendShapeIndex;
                if (faceARkitBlendShapeIndexMap.TryGetValue(featureCoefficient.blendShapeLocation, out mappedBlendShapeIndex))
                {
                    Debug.LogFormat("BlendShapeIndex: {0}, Location: {1}, Coefficient: {2}", mappedBlendShapeIndex, featureCoefficient.blendShapeLocation, featureCoefficient.coefficient);
                    if (mappedBlendShapeIndex >= 0)
                    {
                        skinnedMeshRenderer.SetBlendShapeWeight(mappedBlendShapeIndex, featureCoefficient.coefficient * blendShapeMappings.CoefficientScale);
                    }
                }
            }
        }
        
    }
}
