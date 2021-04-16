using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.ARKit;

[Serializable]
public class Mapping
{
    public ARKitBlendShapeLocation location;
    public string name;
}

[CreateAssetMenu(fileName = "BlendShapeMapping", menuName = "BlendShapeMapping/Mappings",order = 1)]
public class BlendShapeMappings : ScriptableObject
{
    public float CoefficientScale = 100.0f;

    [SerializeField]
    public List<Mapping> Mappings = new List<Mapping>
    {
        new Mapping{location = ARKitBlendShapeLocation.EyeBlinkLeft, name = "Blink_L"},
        new Mapping{location = ARKitBlendShapeLocation.EyeBlinkRight, name = "Blink_R"},
        new Mapping{location = ARKitBlendShapeLocation.MouthClose, name = "MouthClose"},
        new Mapping{location = ARKitBlendShapeLocation.MouthSmileLeft, name = "Smile"},
        new Mapping{location = ARKitBlendShapeLocation.MouthSmileRight, name = "Smile"},
        new Mapping{location = ARKitBlendShapeLocation.JawOpen, name = "MouthOpen"}
    };
}
